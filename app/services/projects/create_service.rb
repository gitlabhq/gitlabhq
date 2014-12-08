module Projects
  class CreateService < BaseService
    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      @project = Project.new(params)

      # Reset visibility levet if is not allowed to set it
      unless Gitlab::VisibilityLevel.allowed_for?(current_user, params[:visibility_level])
        @project.visibility_level = default_features.visibility_level
      end

      # Parametrize path for project
      #
      # Ex.
      #  'GitLab HQ'.parameterize => "gitlab-hq"
      #
      @project.path = @project.name.dup.parameterize unless @project.path.present?

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

      Project.transaction do
        @project.save

        unless @project.import?
          unless @project.create_repository
            raise 'Failed to create repository'
          end
        end
      end

      if @project.persisted?
        if @project.wiki_enabled?
          @project.create_wiki
        end

        after_create_actions
      end

      @project
    rescue => ex
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
      system_hook_service.execute_hooks_for(@project, :create)

      unless @project.group
        @project.team << [current_user, :master]
      end

      @project.update_column(:last_activity_at, @project.created_at)

      if @project.import?
        @project.import_start
      end
    end
  end
end
