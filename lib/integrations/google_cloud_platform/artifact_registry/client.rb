# frozen_string_literal: true

module Integrations
  module GoogleCloudPlatform
    module ArtifactRegistry
      class Client < Integrations::GoogleCloudPlatform::BaseClient
        PAGE_SIZE = 10

        def initialize(project:, user:, gcp_project_id:, gcp_location:, gcp_repository:, gcp_wlif:)
          super(project: project, user: user)
          @gcp_project_id = gcp_project_id
          @gcp_location = gcp_location
          @gcp_repository = gcp_repository
          @gcp_wlif = gcp_wlif
        end

        def list_docker_images(page_token: nil)
          response = ::Gitlab::HTTP.get(
            list_docker_images_url,
            headers: headers,
            query: query_params(page_token: page_token),
            format: :plain # disable httparty json parsing
          )

          if response.success?
            ::Gitlab::Json.parse(response.body, symbolize_keys: true)
          else
            {}
          end
        end

        private

        def list_docker_images_url
          "#{GLGO_BASE_URL}/gcp/ar/" \
            "projects/#{@gcp_project_id}/" \
            "locations/#{@gcp_location}/" \
            "repositories/#{@gcp_repository}/docker"
        end

        def query_params(page_token: nil)
          {
            page_token: page_token,
            page_size: PAGE_SIZE
          }.compact
        end

        def headers
          jwt = encoded_jwt(wlif: @gcp_wlif)
          {
            'Authorization' => "Bearer #{jwt}"
          }
        end
      end
    end
  end
end
