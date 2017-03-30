module ContainerRegistry
  ##
  # Service for creating a container repository.
  #
  # It is usually executed before registry authenticator returns
  # a token for given request.
  #
  class CreateRepositoryService < BaseService
    def execute(path)
      @path = path

      return if path.has_repository?

      unless user_can_create? || legacy_trigger_can_create?
        raise Gitlab::Access::AccessDeniedError
      end

      ContainerRepository.create_from_path(path)
    end

    private

    def user_can_create?
      can?(@current_user, :create_container_image, @path.repository_project)
    end

    ## TODO, remove it after removing legacy triggers.
    #
    def legacy_trigger_can_create?
      @current_user.nil? && @project == @path.repository_project
    end
  end
end
