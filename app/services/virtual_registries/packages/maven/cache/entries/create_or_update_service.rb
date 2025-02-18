# frozen_string_literal: true

module VirtualRegistries
  module Packages
    module Maven
      module Cache
        module Entries
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
                file_sha1: file.sha1,
                content_type: content_type
              }.compact_blank
              updates[:file_md5] = file.md5 unless Gitlab::FIPS.enabled?

              ce = ::VirtualRegistries::Packages::Maven::Cache::Entry.create_or_update_by!(
                group_id: upstream.group_id,
                upstream: upstream,
                relative_path: relative_path,
                updates: updates
              )

              ServiceResponse.success(payload: { cache_entry: ce })
            rescue StandardError => e
              Gitlab::ErrorTracking.track_exception(
                e,
                upstream_id: upstream.id,
                group_id: upstream.group_id,
                class: self.class.name
              )
              ServiceResponse.error(message: e.message, reason: :persistence_error)
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
end
