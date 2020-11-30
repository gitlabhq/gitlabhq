# frozen_string_literal: true

module Projects
  class CreateService < BaseService
    include ValidatesClassificationLabel

    def initialize(user, params)
      @current_user, @params  = user, params.dup
      @skip_wiki              = @params.delete(:skip_wiki)
      @initialize_with_readme = Gitlab::Utils.to_boolean(@params.delete(:initialize_with_readme))
      @import_data            = @params.delete(:import_data)
      @relations_block        = @params.delete(:relations_block)
    end

    def execute
      if create_from_template?
        return ::Projects::CreateFromTemplateService.new(current_user, params).execute
      end

      @project = Project.new(params)

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
        unless allowed_namespace?(current_user, namespace_id)
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
    rescue => e
      @project.errors.add(:base, e.message) if @project
      fail(error: e.message)
    end

    protected

    def deny_namespace
      @project.errors.add(:namespace, "is not valid")
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def allowed_namespace?(user, namespace_id)
      namespace = Namespace.find_by(id: namespace_id)
      current_user.can?(:create_projects, namespace)
    end
    # rubocop: enable CodeReuse/ActiveRecord

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
      create_prometheus_service

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

        if Feature.enabled?(:specialized_project_authorization_workers)
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
          @project.group.refresh_members_authorized_projects(blocking: false)
        end
      else
        @project.add_maintainer(@project.namespace.owner, current_user: current_user)
      end
    end

    def create_readme
      commit_attrs = {
        branch_name: @project.default_branch || 'master',
        commit_message: 'Initial commit',
        file_path: 'README.md',
        file_content: "# #{@project.name}\n\n#{@project.description}"
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
          Service.create_from_active_default_integrations(@project, :project_id, with_templates: true)

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

    def create_prometheus_service
      service = @project.find_or_initialize_service(::PrometheusService.to_param)

      # If the service has already been inserted in the database, that
      # means it came from a template, and there's nothing more to do.
      return if service.persisted?

      if service.prometheus_available?
        service.save!
      else
        @project.prometheus_service = nil
      end

    rescue ActiveRecord::RecordInvalid => e
      Gitlab::ErrorTracking.track_exception(e, extra: { project_id: project.id })
      @project.prometheus_service = nil
    end

    def set_project_name_from_path
      # Set project name from path
      if @project.name.present? && @project.path.present?
        # if both name and path set - everything is ok
      elsif @project.path.present?
        # Set project name from path
        @project.name = @project.path.dup
      elsif @project.name.present?
        # For compatibility - set path from name
        # TODO: remove this in 8.0
        @project.path = @project.name.dup.parameterize
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
  end
end

Projects::CreateService.prepend_if_ee('EE::Projects::CreateService')

# Measurable should be at the bottom of the ancestor chain, so it will measure execution of EE::Projects::CreateService as well
Projects::CreateService.prepend(Measurable)
