# frozen_string_literal: true

module Registry
  module ConnectionErrorsHandler
    extend ActiveSupport::Concern

    included do
      rescue_from ContainerRegistry::Path::InvalidRegistryPathError, with: :invalid_registry_path
      rescue_from Faraday::Error, with: :connection_error

      before_action :ping_container_registry
    end

    private

    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    # These instance variables are only read by a view helper to pass
    # them to the frontend
    # See app/views/projects/registry/repositories/index.html.haml
    # app/views/groups/registry/repositories/index.html.haml
    def invalid_registry_path
      @invalid_path_error = true

      render :index
    end

    def connection_error
      @connection_error = true

      render :index
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    def ping_container_registry
      ContainerRegistry::Client.registry_info
    end
  end
end
