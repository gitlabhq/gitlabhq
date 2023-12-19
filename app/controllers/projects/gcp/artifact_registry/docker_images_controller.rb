# frozen_string_literal: true

module Projects
  module Gcp
    module ArtifactRegistry
      class DockerImagesController < Projects::Gcp::ArtifactRegistry::BaseController
        before_action :require_gcp_params
        before_action :handle_pagination

        REPO_NAME_REGEX = %r{/repositories/(.*)/dockerImages/}

        def index
          result = service.execute(page_token: params[:page_token])

          if result.success?
            @docker_images = process_docker_images(result.payload[:images] || [])
            @next_page_token = result.payload[:next_page_token]
            @artifact_repository_name = artifact_repository_name
            @error = @docker_images.blank? ? 'No docker images' : false
          else
            @error = result.message
          end
        end

        private

        def service
          ::Integrations::GoogleCloudPlatform::ArtifactRegistry::ListDockerImagesService.new(
            project: @project,
            current_user: current_user,
            params: {
              gcp_project_id: gcp_project_id,
              gcp_location: gcp_location,
              gcp_repository: gcp_ar_repository,
              gcp_wlif: gcp_wlif_url
            }
          )
        end

        def process_docker_images(raw_images)
          raw_images.map { |r| process_docker_image(r) }
        end

        def process_docker_image(raw_image)
          DockerImage.new(
            name: raw_image[:name],
            uri: raw_image[:uri],
            tags: raw_image[:tags],
            image_size_bytes: raw_image[:size_bytes],
            media_type: raw_image[:media_type],
            upload_time: raw_image[:uploaded_at],
            build_time: raw_image[:built_at],
            update_time: raw_image[:updated_at]
          )
        end

        def artifact_repository_name
          return unless @docker_images.present?

          (@docker_images.first.name || '')[REPO_NAME_REGEX, 1]
        end

        def handle_pagination
          @page = Integer(params[:page] || 1)
          @page_tokens = {}
          @previous_page_token = nil

          if params[:page_tokens]
            @page_tokens = ::Gitlab::Json.parse(Base64.decode64(params[:page_tokens]))
            @previous_page_token = @page_tokens[(@page - 1).to_s]
          end

          @page_tokens[@page.to_s] = params[:page_token]
          @page_tokens = Base64.encode64(::Gitlab::Json.dump(@page_tokens.compact))
        end

        def require_gcp_params
          return unless gcp_project_id.blank? || gcp_location.blank? || gcp_ar_repository.blank? || gcp_wlif_url.blank?

          redirect_to new_namespace_project_gcp_artifact_registry_setup_path
        end

        def gcp_project_id
          params[:gcp_project_id]
        end

        def gcp_location
          params[:gcp_location]
        end

        def gcp_ar_repository
          params[:gcp_ar_repository]
        end

        def gcp_wlif_url
          params[:gcp_wlif_url]
        end

        class DockerImage
          include ActiveModel::API

          attr_accessor :name, :uri, :tags, :image_size_bytes, :upload_time, :media_type, :build_time, :update_time

          SHORT_NAME_REGEX = %r{dockerImages/(.*)$}

          def short_name
            (name || '')[SHORT_NAME_REGEX, 1]
          end

          def updated_at
            return unless update_time

            Time.zone.parse(update_time)
          end

          def built_at
            return unless build_time

            Time.zone.parse(build_time)
          end

          def uploaded_at
            return unless upload_time

            Time.zone.parse(upload_time)
          end

          def details_url
            "https://#{uri}"
          end
        end
      end
    end
  end
end
