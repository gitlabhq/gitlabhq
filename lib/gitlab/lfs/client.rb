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

        raise BatchSubmitError unless rsp.success?

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
          headers: {
            'Content-Length' => object.size.to_s,
            'Content-Type' => 'application/octet-stream',
            'User-Agent' => GIT_LFS_USER_AGENT
          }.merge(upload_action['header'] || {})
        }

        authenticated = true if params[:headers].key?('Authorization')
        params[:basic_auth] = basic_auth unless authenticated

        rsp = Gitlab::HTTP.put(upload_action['href'], params)

        raise ObjectUploadError unless rsp.success?
      ensure
        file&.close
      end

      def verify!(object, verify_action, authenticated:)
        params = {
          body: object.to_json(only: [:oid, :size]),
          headers: build_request_headers(verify_action['header'])
        }

        authenticated = true if params[:headers].key?('Authorization')
        params[:basic_auth] = basic_auth unless authenticated

        rsp = Gitlab::HTTP.post(verify_action['href'], params)

        raise ObjectVerifyError unless rsp.success?
      end

      private

      def build_request_headers(extra_headers = nil)
        DEFAULT_HEADERS.merge(extra_headers || {})
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

      class BatchSubmitError < StandardError
        def message
          "Failed to submit batch"
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

      class ObjectUploadError < StandardError
        def message
          "Failed to upload object"
        end
      end

      class ObjectVerifyError < StandardError
        def message
          "Failed to verify object"
        end
      end
    end
  end
end
