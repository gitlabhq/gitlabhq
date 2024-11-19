# frozen_string_literal: true

module API
  module Entities
    module VirtualRegistries
      module Packages
        module Maven
          class CachedResponse < Grape::Entity
            expose :cached_response_id do |cached_response, _options|
              Base64.urlsafe_encode64(cached_response.relative_path)
            end

            expose :group_id,
              :upstream_id,
              :upstream_checked_at,
              :file,
              :file_md5,
              :file_sha1,
              :size,
              :downloaded_at,
              :relative_path,
              :upstream_etag,
              :content_type,
              :created_at,
              :updated_at
          end
        end
      end
    end
  end
end
