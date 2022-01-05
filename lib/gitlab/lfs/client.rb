# frozen_string_literal: true
module Gitlab
  module Lfs
    # Gitlab::Lfs::Client implements a simple LFS client, designed to talk to
    # LFS servers as described in these documents:
    #   * https://github.com/git-lfs/git-lfs/blob/master/docs/api/batch.md
    #   * https://github.com/git-lfs/git-lfs/blob/master/docs/api/basic-transfers.md
    class Client
      GIT_LFS_CONTENT_TYPE = 'application/vnd.git-lfs+json'
      GIT_LFS_USER_AGENT = "GitLab #{Gitlab::VERSION} LFS client"
      DEFAULT_HEADERS = {
        'Accept' => GIT_LFS_CONTENT_TYPE,
        'Content-Type' => GIT_LFS_CONTENT_TYPE,
        'User-Agent' => GIT_LFS_USER_AGENT
      }.freeze

      attr_reader :base_url

      def initialize(base_url, credentials:)
        @base_url = base_url
        @credentials = credentials
      end

      def batch!(operation, objects)
        body = {
          operation: operation,
          transfers: ['basic'],
          # We don't know `ref`, so can't send it
          objects: objects.as_json(only: [:oid, :size])
        }

        rsp = Gitlab::HTTP.post(
          batch_url,
          basic_auth: basic_auth,
          body: body.to_json,
          headers: build_request_headers
        )

        raise BatchSubmitError.new(http_response: rsp) unless rsp.success?

        # HTTParty provides rsp.parsed_response, but it only kicks in for the
        # application/json content type in the response, which we can't rely on
        body = Gitlab::Json.parse(rsp.body)
        transfer = body.fetch('transfer', 'basic')

        raise UnsupportedTransferError, transfer.inspect unless transfer == 'basic'

        body
      end

      def upload!(object, upload_action, authenticated:)
        file = object.file.open

        params = {
          body_stream: file,
          headers: upload_headers(object, upload_action)
        }

        url = set_basic_auth_and_extract_lfs_url!(params, upload_action['href'])
        rsp = Gitlab::HTTP.put(url, params)

        raise ObjectUploadError.new(http_response: rsp) unless rsp.success?
      ensure
        file&.close
      end

      def verify!(object, verify_action, authenticated:)
        params = {
          body: object.to_json(only: [:oid, :size]),
          headers: build_request_headers(verify_action['header'])
        }

        url = set_basic_auth_and_extract_lfs_url!(params, verify_action['href'])
        rsp = Gitlab::HTTP.post(url, params)

        raise ObjectVerifyError.new(http_response: rsp) unless rsp.success?
      end

      private

      def set_basic_auth_and_extract_lfs_url!(params, raw_url)
        authenticated = true if params[:headers].key?('Authorization')
        params[:basic_auth] = basic_auth unless authenticated
        strip_userinfo = authenticated || params[:basic_auth].present?
        lfs_url(raw_url, strip_userinfo)
      end

      def build_request_headers(extra_headers = nil)
        DEFAULT_HEADERS.merge(extra_headers || {})
      end

      def upload_headers(object, upload_action)
        # This uses the httprb library to handle case-insensitive HTTP headers
        headers = ::HTTP::Headers.new
        headers.merge!(upload_action['header'])
        transfer_encodings = Array(headers['Transfer-Encoding']&.split(',')).map(&:strip)

        headers['Content-Length'] = object.size.to_s unless transfer_encodings.include?('chunked')
        headers['Content-Type'] = 'application/octet-stream'
        headers['User-Agent'] = GIT_LFS_USER_AGENT

        headers.to_h
      end

      def lfs_url(raw_url, strip_userinfo)
        # HTTParty will give precedence to the username/password
        # specified in the URL. This causes problems with Azure DevOps,
        # which includes a username in the URL. Stripping the userinfo
        # from the URL allows the provided HTTP Basic Authentication
        # credentials to be used.
        if strip_userinfo
          Gitlab::UrlSanitizer.new(raw_url).sanitized_url
        else
          raw_url
        end
      end

      attr_reader :credentials

      def batch_url
        base_url + '/info/lfs/objects/batch'
      end

      def basic_auth
        # Some legacy credentials have a nil auth_method, which means password
        # https://gitlab.com/gitlab-org/gitlab/-/issues/328674
        return unless credentials.fetch(:auth_method, 'password') == 'password'
        return if credentials.empty?

        { username: credentials[:user], password: credentials[:password] }
      end

      class HttpError < StandardError
        def initialize(http_response:)
          super

          @http_response = http_response
        end

        def http_error
          "HTTP status #{@http_response.code}"
        end
      end

      class BatchSubmitError < HttpError
        def message
          "Failed to submit batch: #{http_error}"
        end
      end

      class UnsupportedTransferError < StandardError
        def initialize(transfer = nil)
          super
          @transfer = transfer
        end

        def message
          "Unsupported transfer: #{@transfer}"
        end
      end

      class ObjectUploadError < HttpError
        def message
          "Failed to upload object: #{http_error}"
        end
      end

      class ObjectVerifyError < HttpError
        def message
          "Failed to verify object: #{http_error}"
        end
      end
    end
  end
end
