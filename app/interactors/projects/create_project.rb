module Projects
  class CreateProject < Iteractor::Base
    def setup
      context.fail!(message: 'Invalid user') if context[:user].blank?
      context.fail!(message: 'Invalid params') if context[:params].blank?

      unless allowed_namespace?(context[:user], context[:params][:namespace_id])
        context.fail!(message: 'Namespace invalid')
      end
    end

    def perform
      params = context[:params]
      current_user = context[:user]

      @project = Project.new(params)

      # Reset visibility levet if is not allowed to set it
      unless Gitlab::VisibilityLevel.allowed_for?(current_user, params[:visibility_level])
        @project.visibility_level = default_features.visibility_level
      end

      # Parametrize path for project
      #
      # Ex.
      #  'GitLab HQ'.parameterize => 'gitlab-hq'
      #
      if @project.path.blank?
        @project.path = @project.name.dup.parameterize
      end

      # Set current user namespace if namespace_id is nil
      if @project.namespace_id.blank?
        @project.namespace_id = current_user.namespace_id
      end

      @project.creator = current_user

      if @project.save
        context[:project] = @project

        # System hook execute context
        context[:entity] = @project
        context[:event] = :create

        log_info("#{@project.owner.name} created a new project \'#{@project.name_with_namespace}\'")
      else
        context.fail!(message: 'Unable save project')
      end
    end

    def rollback
      if context[:project].persisted?
        log_info("Project \'#{@project.name_with_namespace}\' was removed in rallback action")
        context[:project].destroy
      else
        # Project not persisted. No DB changes
        context[:project].errors.add(:base, "Can't save project. Please try again later")
      end
    end

    private

    def allowed_namespace?(user, namespace_id)
      namespace = Namespace.find_by(id: namespace_id)
      user.can?(:create_projects, namespace)
    end
  end
end
