# frozen_string_literal: true

# This service lists the download link from a remote source based on the
# oids provided
module Projects
  module LfsPointers
    class LfsDownloadLinkListService < BaseService
      DOWNLOAD_ACTION = 'download'

      # This could be different per server, but it seems like a reasonable value to start with.
      # https://github.com/git-lfs/git-lfs/issues/419
      REQUEST_BATCH_SIZE = 100

      DownloadLinksError = Class.new(StandardError)
      DownloadLinkNotFound = Class.new(StandardError)
      DownloadLinksRequestEntityTooLargeError = Class.new(StandardError)

      attr_reader :remote_uri

      def initialize(project, remote_uri: nil)
        super(project)

        @remote_uri = remote_uri
      end

      # This method accepts two parameters:
      # - oids: hash of oids to query. The structure is { lfs_file_oid => lfs_file_size }
      #
      # Returns an array of LfsDownloadObject
      def execute(oids)
        return [] unless project&.lfs_enabled? && remote_uri && oids.present?

        get_download_links_in_batches(oids)
      end

      private

      def get_download_links_in_batches(oids, batch_size = REQUEST_BATCH_SIZE)
        download_links = []

        oids.each_slice(batch_size) do |batch|
          download_links += get_download_links(batch)
        end

        download_links

      rescue DownloadLinksRequestEntityTooLargeError => e
        # Log this exceptions to see how open it happens
        Gitlab::ErrorTracking
          .track_exception(e, project_id: project&.id, batch_size: batch_size, oids_count: oids.count)

        # Try again with a smaller batch
        batch_size /= 2

        retry if batch_size > REQUEST_BATCH_SIZE / 3

        raise DownloadLinksError, 'Unable to download due to RequestEntityTooLarge errors'
      end

      def get_download_links(oids)
        response = Gitlab::HTTP.post(remote_uri,
                                     body: request_body(oids),
                                     headers: headers)

        raise DownloadLinksRequestEntityTooLargeError if response.request_entity_too_large?
        raise DownloadLinksError, response.message unless response.success?

        # Since the LFS Batch API may return a Content-Ttpe of
        # application/vnd.git-lfs+json
        # (https://github.com/git-lfs/git-lfs/blob/master/docs/api/batch.md#requests),
        # HTTParty does not know this is actually JSON.
        data = Gitlab::Json.parse(response.body)

        raise DownloadLinksError, "LFS Batch API did return any objects" unless data.is_a?(Hash) && data.key?('objects')

        parse_response_links(data['objects'])
      rescue JSON::ParserError
        raise DownloadLinksError, "LFS Batch API response is not JSON"
      end

      def parse_response_links(objects_response)
        objects_response.each_with_object([]) do |entry, link_list|
          link = entry.dig('actions', DOWNLOAD_ACTION, 'href')
          headers = entry.dig('actions', DOWNLOAD_ACTION, 'header')

          raise DownloadLinkNotFound unless link

          link_list << LfsDownloadObject.new(oid: entry['oid'],
                                             size: entry['size'],
                                             headers: headers,
                                             link: add_credentials(link))
        rescue DownloadLinkNotFound, Addressable::URI::InvalidURIError
          log_error("Link for Lfs Object with oid #{entry['oid']} not found or invalid.")
        end
      end

      def request_body(oids)
        {
          operation: DOWNLOAD_ACTION,
          objects: oids.map { |oid, size| { oid: oid, size: size } }
        }.to_json
      end

      def headers
        {
          'Accept' => LfsRequest::CONTENT_TYPE,
          'Content-Type' => LfsRequest::CONTENT_TYPE
        }.freeze
      end

      def add_credentials(link)
        uri = Addressable::URI.parse(link)

        if should_add_credentials?(uri)
          uri.user = remote_uri.user
          uri.password = remote_uri.password
        end

        uri.to_s
      end

      # The download link can be a local url or an object storage url
      # If the download link has the some host as the import url then
      # we add the same credentials because we may need them
      def should_add_credentials?(link_uri)
        url_credentials? && link_uri.host == remote_uri.host
      end

      def url_credentials?
        remote_uri.user.present? || remote_uri.password.present?
      end
    end
  end
end
