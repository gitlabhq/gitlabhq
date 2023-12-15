# frozen_string_literal: true

module Integrations
  module GoogleCloudPlatform
    module ArtifactRegistry
      class ListDockerImagesService < BaseProjectService
        def execute(page_token: nil)
          return ServiceResponse.error(message: "Access denied") unless allowed?

          ServiceResponse.success(payload: client.list_docker_images(page_token: page_token))
        end

        private

        def allowed?
          can?(current_user, :read_container_image, project)
        end

        def client
          ::Integrations::GoogleCloudPlatform::ArtifactRegistry::Client.new(
            project: project,
            user: current_user,
            gcp_project_id: gcp_project_id,
            gcp_location: gcp_location,
            gcp_repository: gcp_repository,
            gcp_wlif: gcp_wlif
          )
        end

        def gcp_project_id
          params[:gcp_project_id]
        end

        def gcp_location
          params[:gcp_location]
        end

        def gcp_repository
          params[:gcp_repository]
        end

        def gcp_wlif
          params[:gcp_wlif]
        end
      end
    end
  end
end
