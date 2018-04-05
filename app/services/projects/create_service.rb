module Projects
  class CreateService < BaseService
    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      if @params[:template_name]&.present?
        return ::Projects::CreateFromTemplateService.new(current_user, params).execute
      end

      forked_from_project_id = params.delete(:forked_from_project_id)
      import_data = params.delete(:import_data)
      @skip_wiki = params.delete(:skip_wiki)

      @project = Project.new(params)

      # Make sure that the user is allowed to use the specified visibility level
      unless Gitlab::VisibilityLevel.allowed_for?(current_user, @project.visibility_level)
        deny_visibility_level(@project)
        return @project
      end

      unless allowed_fork?(forked_from_project_id)
        @project.errors.add(:forked_from_project_id, 'is forbidden')
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

      yield(@project) if block_given?

      @project.creator = current_user

      if forked_from_project_id
        @project.build_forked_project_link(forked_from_project_id: forked_from_project_id)
      end

      save_project_and_import_data(import_data)

      after_create_actions if @project.persisted?

      import_schedule

      @project
    rescue ActiveRecord::RecordInvalid => e
      message = "Unable to save #{e.record.type}: #{e.record.errors.full_messages.join(", ")} "
      fail(error: message)
    rescue => e
      fail(error: e.message)
    end

    protected

    def deny_namespace
      @project.errors.add(:namespace, "is not valid")
    end

    def allowed_fork?(source_project_id)
      return true if source_project_id.nil?

      source_project = Project.find_by(id: source_project_id)
      current_user.can?(:fork_project, source_project)
    end

    def allowed_namespace?(user, namespace_id)
      namespace = Namespace.find_by(id: namespace_id)
      current_user.can?(:create_projects, namespace)
    end

    def after_create_actions
      log_info("#{@project.owner.name} created a new project \"#{@project.full_name}\"")

      unless @project.gitlab_project_import?
        @project.write_repository_config
        @project.create_wiki unless skip_wiki?
      end

      event_service.create_project(@project, current_user)
      system_hook_service.execute_hooks_for(@project, :create)

      setup_authorizations
    end

    # Refresh the current user's authorizations inline (so they can access the
    # project immediately after this request completes), and any other affected
    # users in the background
    def setup_authorizations
      if @project.group
        @project.group.refresh_members_authorized_projects(blocking: false)
        current_user.refresh_authorized_projects
      else
        @project.add_master(@project.namespace.owner, current_user: current_user)
      end
    end

    def skip_wiki?
      !@project.feature_available?(:wiki, current_user) || @skip_wiki
    end

    def save_project_and_import_data(import_data)
      Project.transaction do
        @project.create_or_update_import_data(data: import_data[:data], credentials: import_data[:credentials]) if import_data

        if @project.save
          unless @project.gitlab_project_import?
            create_services_from_active_templates(@project)
            @project.create_labels
          end

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
      Rails.logger.error(log_message)

      if @project
        @project.errors.add(:base, message)
        @project.mark_import_as_failed(message) if @project.import?
      end

      @project
    end

    def create_services_from_active_templates(project)
      Service.where(template: true, active: true).each do |template|
        service = Service.build_from_template(project.id, template)
        service.save!
      end
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

    private

    def import_schedule
      if @project.errors.empty?
        @project.import_schedule if @project.import? && !@project.bare_repository_import?
      else
        fail(error: @project.errors.full_messages.join(', '))
      end
    end
  end
end
