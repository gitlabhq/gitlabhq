# frozen_string_literal: true

# This service discovers the Lfs files that are linked in repository,
# but not downloaded yet and yields the operation
# on each Lfs file link (url) to remote repository.
module Projects
  module LfsPointers
    class LfsObjectDownloadListService < BaseService
      include Gitlab::Utils::StrongMemoize

      HEAD_REV = 'HEAD'
      LFS_ENDPOINT_PATTERN = /^\t?url\s*=\s*(.+)$/
      LFS_BATCH_API_ENDPOINT = '/info/lfs/objects/batch'

      LfsObjectDownloadListError = Class.new(StandardError)

      def each_list_item(&block)
        return unless context_valid?

        # Downloading the required information and gathering it inside an
        #   LfsDownloadObject for each oid
        LfsDownloadLinkListService
          .new(project, remote_uri: current_endpoint_uri)
          .each_link(missing_lfs_files, &block)
      rescue LfsDownloadLinkListService::DownloadLinksError => e
        raise LfsObjectDownloadListError, "The LFS objects download list couldn't be imported. Error: #{e.message}"
      end

      private

      def context_valid?
        return false unless project&.lfs_enabled?
        return true unless external_lfs_endpoint?

        # If the endpoint host is different from the import_url it means
        # that the repo is using a third party service for storing the LFS files.
        # In this case, we have to disable lfs in the project
        disable_lfs!
        false
      end

      def external_lfs_endpoint?
        lfsconfig_endpoint_uri && lfsconfig_endpoint_uri.host != import_uri.host
      end

      def disable_lfs!
        unless project.update(lfs_enabled: false)
          raise LfsDownloadLinkListService::DownloadLinksError, "Invalid project state"
        end
      end

      # Retrieves all lfs pointers in the repository
      def lfs_pointers_in_repository
        @lfs_pointers_in_repository ||= LfsListService.new(project).execute
      end

      def existing_lfs_objects
        project.lfs_objects
      end

      def existing_lfs_objects_hash
        {}.tap do |hash|
          existing_lfs_objects.find_each do |lfs_object|
            hash[lfs_object.oid] = lfs_object.size
          end
        end
      end

      def missing_lfs_files
        lfs_pointers_in_repository.except(*existing_lfs_objects_hash.keys)
      end

      def lfsconfig_endpoint_uri
        strong_memoize(:lfsconfig_endpoint_uri) do
          # Retrieveing the blob data from the .lfsconfig file
          data = project.repository.lfsconfig_for(HEAD_REV)
          # Parsing the data to retrieve the url
          parsed_data = data&.match(LFS_ENDPOINT_PATTERN)

          if parsed_data
            URI.parse(parsed_data[1]).tap do |endpoint|
              endpoint.user ||= import_uri.user
              endpoint.password ||= import_uri.password
            end
          end
        end
      rescue URI::InvalidURIError
        raise LfsObjectDownloadListError, 'Invalid URL in .lfsconfig file'
      end

      def import_uri
        @import_uri ||= URI.parse(project.import_url)
      rescue URI::InvalidURIError
        raise LfsObjectDownloadListError, 'Invalid project import URL'
      end

      def current_endpoint_uri
        (lfsconfig_endpoint_uri || default_endpoint_uri)
      end

      # The import url must end with '.git' here we ensure it is
      def default_endpoint_uri
        @default_endpoint_uri ||= import_uri.dup.tap do |uri|
          path = uri.path.gsub(%r{/$}, '')
          path += '.git' unless path.ends_with?('.git')
          uri.path = path + LFS_BATCH_API_ENDPOINT
        end
      end
    end
  end
end
