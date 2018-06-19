# This service lists the download link from a remote source based on the
# oids provided
module Projects
  module LfsPointers
    class LfsDownloadLinkListService < BaseService
      DOWNLOAD_ACTION = 'download'.freeze

      DownloadLinksError = Class.new(StandardError)
      DownloadLinkNotFound = Class.new(StandardError)

      attr_reader :remote_uri

      def initialize(project, remote_uri: nil)
        super(project)

        @remote_uri = remote_uri
      end

      # This method accepts two parameters:
      # - oids: hash of oids to query. The structure is { lfs_file_oid => lfs_file_size }
      #
      # Returns a hash with the structure { lfs_file_oids => download_link }
      def execute(oids)
        return {} unless project&.lfs_enabled? && remote_uri && oids.present?

        get_download_links(oids)
      end

      private

      def get_download_links(oids)
        response = Gitlab::HTTP.post(remote_uri,
                                     body: request_body(oids),
                                     headers: headers)

        raise DownloadLinksError, response.message unless response.success?

        parse_response_links(response['objects'])
      end

      def parse_response_links(objects_response)
        objects_response.each_with_object({}) do |entry, link_list|
          begin
            oid = entry['oid']
            link = entry.dig('actions', DOWNLOAD_ACTION, 'href')

            raise DownloadLinkNotFound unless link

            link_list[oid] = add_credentials(link)
          rescue DownloadLinkNotFound, URI::InvalidURIError
            Rails.logger.error("Link for Lfs Object with oid #{oid} not found or invalid.")
          end
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
        uri = URI.parse(link)

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
