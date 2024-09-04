# frozen_string_literal: true

module VirtualRegistries
  module Packages
    module Maven
      module CachedResponses
        class CreateService < ::BaseContainerService
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
            # the uploader's filename function depends on the relative_path.
            # The relative_path needs to be set before the file value is assigned.
            cr = upstream.cached_responses.build(
              group_id: upstream.group_id,
              upstream_etag: etag,
              upstream_checked_at: now,
              size: file.size,
              relative_path: relative_path,
              downloaded_at: now
            )
            cr.update!(file: file)
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
        end
      end
    end
  end
end
