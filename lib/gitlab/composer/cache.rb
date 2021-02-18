# frozen_string_literal: true

require 'tempfile'

module Gitlab
  module Composer
    class Cache
      def initialize(project:, name:, last_page_sha: nil)
        @project = project
        @name = name
        @last_page_sha = last_page_sha
      end

      def execute
        Packages::Composer::Metadatum.transaction do # rubocop: disable CodeReuse/ActiveRecord
          # make sure we lock these records at the start
          locked_package_metadata

          if locked_package_metadata.any?
            mark_pages_for_delete(shas_to_delete)

            create_cache_page!

            # assign the newest page SHA to the packages
            locked_package_metadata.update_all(version_cache_sha: version_index.sha)
          elsif @last_page_sha
            mark_pages_for_delete([@last_page_sha])
          end
        end
      end

      private

      def mark_pages_for_delete(shas)
        Packages::Composer::CacheFile
          .with_namespace(@project.namespace)
          .with_sha(shas)
          .update_all(delete_at: 1.day.from_now)
      end

      def create_cache_page!
        Packages::Composer::CacheFile
          .safe_find_or_create_by!(namespace_id: @project.namespace_id, file_sha256: version_index.sha) do |cache_file|
            cache_file.file = CarrierWaveStringFile.new(version_index.to_json)
          end
      end

      def version_index
        @version_index ||= ::Gitlab::Composer::VersionIndex.new(siblings)
      end

      def siblings
        @siblings ||= locked_package_metadata.map(&:package)
      end

      # find all metadata of the package versions and lock it for update
      def locked_package_metadata
        @locked_package_metadata ||= Packages::Composer::Metadatum
          .for_package(@name, @project.id)
          .locked_for_update
      end

      def shas_to_delete
        locked_package_metadata
          .map(&:version_cache_sha)
          .reject { |sha| sha == version_index.sha }
          .compact
      end
    end
  end
end
