# frozen_string_literal: true

module Projects
  class CreateService < BaseService
    include ValidatesClassificationLabel

    def initialize(user, params)
      @current_user = user
      @params = params.dup
      @skip_wiki = @params.delete(:skip_wiki)
      @initialize_with_readme = Gitlab::Utils.to_boolean(@params.delete(:initialize_with_readme))
      @import_data = @params.delete(:import_data)
      @relations_block = @params.delete(:relations_block)
      @default_branch = @params.delete(:default_branch)

      build_topics
    end

    def execute
      if create_from_template?
        return ::Projects::CreateFromTemplateService.new(current_user, params).execute
      end

      @project = Project.new(params)

      @project.visibility_level = @project.group.visibility_level unless @project.visibility_level_allowed_by_group?

      # If a project is newly created it should have shared runners settings
      # based on its group having it enabled. This is like the "default value"
      @project.shared_runners_enabled = false if !params.key?(:shared_runners_enabled) && @project.group && @project.group.shared_runners_setting != 'enabled'

      # Make sure that the user is allowed to use the specified visibility level
      if project_visibility.restricted?
        deny_visibility_level(@project, project_visibility.visibility_level)
        return @project
      end

      set_project_name_from_path

      # get namespace id
      namespace_id = params[:namespace_id]

      if namespace_id
        # Find matching namespace and check if it allowed
        # for current user if namespace_id passed.
        unless current_user.can?(:create_projects, project_namespace)
          @project.namespace_id = nil
          deny_namespace
          return @project
        end
      else
        # Set current user namespace if namespace_id is nil
        @project.namespace_id = current_user.namespace_id
      end

      @relations_block&.call(@project)
      yield(@project) if block_given?

      validate_classification_label(@project, :external_authorization_classification_label)

      # If the block added errors, don't try to save the project
      return @project if @project.errors.any?

      @project.creator = current_user

      save_project_and_import_data

      Gitlab::ApplicationContext.with_context(related_class: "Projects::CreateService", project: @project) do
        after_create_actions if @project.persisted?

        import_schedule
      end

      @project
    rescue ActiveRecord::RecordInvalid => e
      message = "Unable to save #{e.inspect}: #{e.record.errors.full_messages.join(", ")}"
      fail(error: message)
    rescue StandardError => e
      @project.errors.add(:base, e.message) if @project
      fail(error: e.message)
    end

    protected

    def deny_namespace
      @project.errors.add(:namespace, "is not valid")
    end

    def after_create_actions
      log_info("#{@project.owner.name} created a new project \"#{@project.full_name}\"")

      # Skip writing the config for project imports/forks because it
      # will always fail since the Git directory doesn't exist until
      # a background job creates it (see Project#add_import_job).
      @project.write_repository_config unless @project.import?

      unless @project.gitlab_project_import?
        @project.create_wiki unless skip_wiki?
      end

      @project.track_project_repository
      @project.create_project_setting unless @project.project_setting

      event_service.create_project(@project, current_user)
      system_hook_service.execute_hooks_for(@project, :create)

      setup_authorizations

      current_user.invalidate_personal_projects_count

      Projects::PostCreationWorker.perform_async(@project.id)

      create_readme if @initialize_with_readme
    end

    # Add an authorization for the current user authorizations inline
    # (so they can access the project immediately after this request
    # completes), and any other affected users in the background
    def setup_authorizations
      if @project.group
        group_access_level = @project.group.max_member_access_for_user(current_user,
                                                                       only_concrete_membership: true)

        if group_access_level > GroupMember::NO_ACCESS
          current_user.project_authorizations.safe_find_or_create_by!(
            project: @project,
            access_level: group_access_level)
        end

        AuthorizedProjectUpdate::ProjectCreateWorker.perform_async(@project.id)
        # AuthorizedProjectsWorker uses an exclusive lease per user but
        # specialized workers might have synchronization issues. Until we
        # compare the inconsistency rates of both approaches, we still run
        # AuthorizedProjectsWorker but with some delay and lower urgency as a
        # safety net.
        @project.group.refresh_members_authorized_projects(
          blocking: false,
          priority: UserProjectAccessChangedService::LOW_PRIORITY
        )
      else
        @project.add_maintainer(@project.namespace.owner, current_user: current_user)
      end
    end

    def create_readme
      commit_attrs = {
        branch_name: @default_branch.presence || @project.default_branch_or_main,
        commit_message: 'Initial commit',
        file_path: 'README.md',
        file_content: experiment(:new_project_readme_content, namespace: @project.namespace).run_with(@project)
      }

      Files::CreateService.new(@project, current_user, commit_attrs).execute
    end

    def skip_wiki?
      !@project.feature_available?(:wiki, current_user) || @skip_wiki
    end

    def save_project_and_import_data
      Project.transaction do
        @project.create_or_update_import_data(data: @import_data[:data], credentials: @import_data[:credentials]) if @import_data

        if @project.save
          Integration.create_from_active_default_integrations(@project, :project_id)

          @project.create_labels unless @project.gitlab_project_import?

          unless @project.import?
            raise 'Failed to create repository' unless @project.create_repository
          end
        end
      end
    end

    def fail(error:)
      message = "Unable to save project. Error: #{error}"
      log_message = message.dup

      log_message << " Project ID: #{@project.id}" if @project&.id
      Gitlab::AppLogger.error(log_message)

      if @project && @project.persisted? && @project.import_state
        @project.import_state.mark_as_failed(message)
      end

      @project
    end

    def set_project_name_from_path
      # if both name and path set - everything is ok
      return if @project.name.present? && @project.path.present?

      if @project.path.present?
        # Set project name from path
        @project.name = @project.path.dup
      elsif @project.name.present?
        # For compatibility - set path from name
        @project.path = @project.name.dup

        # TODO: Retained for backwards compatibility. Remove in API v5.
        #       When removed, validation errors will get bubbled up automatically.
        #       See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/52725
        unless @project.path.match?(Gitlab::PathRegex.project_path_format_regex)
          @project.path = @project.path.parameterize
        end
      end
    end

    def extra_attributes_for_measurement
      {
        current_user: current_user&.name,
        project_full_path: "#{project_namespace&.full_path}/#{@params[:path]}"
      }
    end

    private

    def project_namespace
      @project_namespace ||= Namespace.find_by_id(@params[:namespace_id]) || current_user.namespace
    end

    def create_from_template?
      @params[:template_name].present? || @params[:template_project_id].present?
    end

    def import_schedule
      if @project.errors.empty?
        @project.import_state.schedule if @project.import? && !@project.bare_repository_import?
      else
        fail(error: @project.errors.full_messages.join(', '))
      end
    end

    def project_visibility
      @project_visibility ||= Gitlab::VisibilityLevelChecker
        .new(current_user, @project, project_params: { import_data: @import_data })
        .level_restricted?
    end

    def build_topics
      topics = params.delete(:topics)
      tag_list = params.delete(:tag_list)
      topic_list = topics || tag_list

      params[:topic_list] ||= topic_list if topic_list
    end
  end
end

Projects::CreateService.prepend_mod_with('Projects::CreateService')

# Measurable should be at the bottom of the ancestor chain, so it will measure execution of EE::Projects::CreateService as well
Projects::CreateService.prepend(Measurable)
