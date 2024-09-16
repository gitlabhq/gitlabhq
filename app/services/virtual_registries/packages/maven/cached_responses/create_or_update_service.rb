# frozen_string_literal: true

module VirtualRegistries
  module Packages
    module Maven
      module CachedResponses
        class CreateOrUpdateService < ::BaseContainerService
          alias_method :upstream, :container

          ERRORS = {
            unauthorized: ServiceResponse.error(message: 'Unauthorized', reason: :unauthorized),
            path_not_present: ServiceResponse.error(message: 'Parameter path not present', reason: :path_not_present),
            file_not_present: ServiceResponse.error(message: 'Parameter file not present', reason: :file_not_present)
          }.freeze

          def initialize(upstream:, current_user: nil, params: {})
            super(container: upstream, current_user: current_user, params: params)
          end

          def execute
            return ERRORS[:path_not_present] unless path.present?
            return ERRORS[:file_not_present] unless file.present?
            return ERRORS[:unauthorized] unless allowed?

            now = Time.zone.now
            updates = {
              upstream_etag: etag,
              upstream_checked_at: now,
              file: file,
              size: file.size,
              downloaded_at: now,
              content_type: content_type
            }

            cr = ::VirtualRegistries::Packages::Maven::CachedResponse.create_or_update_by!(
              group_id: upstream.group_id,
              upstream: upstream,
              relative_path: relative_path,
              updates: updates
            )

            ServiceResponse.success(payload: { cached_response: cr })
          end

          private

          def allowed?
            can?(current_user, :read_virtual_registry, upstream)
          end

          def file
            params[:file]
          end

          def path
            params[:path]
          end

          def relative_path
            "/#{path}"
          end

          def etag
            params[:etag]
          end

          def content_type
            params[:content_type]
          end
        end
      end
    end
  end
end
