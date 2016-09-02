module Projects
  class CreateService < BaseService
    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      forked_from_project_id = params.delete(:forked_from_project_id)
      import_data = params.delete(:import_data)
      @project = Project.new(params)

      # Make sure that the user is allowed to use the specified visibility level
      unless Gitlab::VisibilityLevel.allowed_for?(current_user, params[:visibility_level])
        deny_visibility_level(@project)
        return @project
      end

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

      @project.creator = current_user

      if forked_from_project_id
        @project.build_forked_project_link(forked_from_project_id: forked_from_project_id)
      end

      save_project_and_import_data(import_data)

      @project.import_start if @project.import?

      after_create_actions if @project.persisted?

      if @project.errors.empty?
        @project.add_import_job if @project.import?
      else
        fail(error: @project.errors.full_messages.join(', '))
      end
      @project
    rescue => e
      fail(error: e.message)
    end

    protected

    def deny_namespace
      @project.errors.add(:namespace, "is not valid")
    end

    def allowed_namespace?(user, namespace_id)
      namespace = Namespace.find_by(id: namespace_id)
      current_user.can?(:create_projects, namespace)
    end

    def after_create_actions
      log_info("#{@project.owner.name} created a new project \"#{@project.name_with_namespace}\"")

      unless @project.gitlab_project_import?
        @project.create_wiki if @project.feature_available?(:wiki, current_user)
        @project.build_missing_services

        @project.create_labels
      end

      event_service.create_project(@project, current_user)
      system_hook_service.execute_hooks_for(@project, :create)

      unless @project.group || @project.gitlab_project_import?
        @project.team << [current_user, :master, current_user]
      end

      predefined_push_rule = PushRule.find_by(is_sample: true)

      if predefined_push_rule
        push_rule = predefined_push_rule.dup.tap{ |gh| gh.is_sample = false }
        project.push_rule = push_rule
      end
    end

    def save_project_and_import_data(import_data)
      Project.transaction do
        @project.create_or_update_import_data(data: import_data[:data], credentials: import_data[:credentials]) if import_data

        if @project.save && !@project.import?
          raise 'Failed to create repository' unless @project.create_repository
        end
      end
    end

    def fail(error:)
      message = "Unable to save project. Error: #{error}"
      message << "Project ID: #{@project.id}" if @project && @project.id

      Rails.logger.error(message)

      if @project && @project.import?
        @project.errors.add(:base, message)
        @project.mark_import_as_failed(message)
      end

      @project
    end
  end
end
