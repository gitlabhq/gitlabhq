module Projects
  class CreateService < BaseService
    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      forked_from_project_id = params.delete(:forked_from_project_id)

      @project = Project.new(params)

      # Make sure that the user is allowed to use the specified visibility
      # level
      unless Gitlab::VisibilityLevel.allowed_for?(current_user,
                                                  params[:visibility_level])
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

      Project.transaction do
        @project.save

        if @project.persisted? && !@project.import?
          unless @project.create_repository
            raise 'Failed to create repository'
          end
        end
      end

      after_create_actions if @project.persisted?

      @project
    rescue
      @project.errors.add(:base, "Can't save project. Please try again later")
      @project
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

      @project.create_wiki if @project.wiki_enabled?

      @project.build_missing_services

      @project.create_labels

      event_service.create_project(@project, current_user)
      system_hook_service.execute_hooks_for(@project, :create)

      unless @project.group
        @project.team << [current_user, :master, current_user]
      end

      @project.import_start if @project.import?
    end
  end
end
