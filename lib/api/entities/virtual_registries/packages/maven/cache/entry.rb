# frozen_string_literal: true

module API
  module Entities
    module VirtualRegistries
      module Packages
        module Maven
          module Cache
            class Entry < Grape::Entity
              expose :id do |cache_entry, _options|
                Base64.urlsafe_encode64("#{cache_entry.upstream_id} #{cache_entry.relative_path}")
              end

              expose :group_id,
                :upstream_id,
                :upstream_checked_at,
                :file,
                :file_md5,
                :file_sha1,
                :size,
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
end
