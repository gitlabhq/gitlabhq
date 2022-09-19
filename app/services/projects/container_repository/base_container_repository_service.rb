# frozen_string_literal: true

module Projects
  module ContainerRepository
    class BaseContainerRepositoryService < ::BaseContainerService
      include ::Gitlab::Utils::StrongMemoize

      alias_method :container_repository, :container

      def initialize(container_repository:, current_user: nil, params: {})
        super(container: container_repository, current_user: current_user, params: params)
      end

      delegate :project, to: :container_repository
    end
  end
end
