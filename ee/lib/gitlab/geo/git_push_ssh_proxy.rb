# frozen_string_literal: true

module Gitlab
  module Geo
    class GitPushSSHProxy
      HTTP_READ_TIMEOUT = 10

      INFO_REFS_CONTENT_TYPE = 'application/x-git-upload-pack-request'.freeze
      PUSH_CONTENT_TYPE = 'application/x-git-receive-pack-request'.freeze
      PUSH_ACCEPT = 'application/x-git-receive-pack-result'.freeze

      MustBeASecondaryNode = Class.new(StandardError)

      class APIResponse
        attr_reader :code, :body

        def initialize(code, body)
          @code = code
          @body = body
        end

        def self.from_http_response(response, primary_repo)
          success = response.is_a?(Net::HTTPSuccess)
          body = response.body.to_s

          if success
            result = Base64.encode64(body)
          else
            message = failed_message(body, primary_repo)
          end

          new(response.code.to_i, status: success, message: message, result: result)
        end

        def self.failed_message(str, primary_repo)
          "Failed to contact primary #{primary_repo}\nError: #{str}"
        end
      end

      class FailedAPIResponse < APIResponse
        def self.from_exception(ex_message, primary_repo, code: 500)
          new(code.to_i,
              status: false,
              message: failed_message(ex_message, primary_repo),
              result: nil)
        end
      end

      def initialize(data)
        @data = data
      end

      def self.inform_client_message(primary_repo_ssh)
        "You're pushing to a Geo secondary.\nWe'll help you by proxying this request to the primary: #{primary_repo_ssh}"
      end

      def info_refs
        ensure_secondary!

        url = "#{primary_repo}/info/refs?service=git-receive-pack"
        headers = { 'Content-Type' => INFO_REFS_CONTENT_TYPE }

        resp = get(url, headers)
        resp.body = remove_http_service_fragment_from(resp.body) if resp.is_a?(Net::HTTPSuccess)

        APIResponse.from_http_response(resp, primary_repo)
      rescue => e
        handle_exception(e)
      end

      def push(encoded_info_refs_response)
        ensure_secondary!

        url = "#{primary_repo}/git-receive-pack"
        headers = { 'Content-Type' => PUSH_CONTENT_TYPE, 'Accept' => PUSH_ACCEPT }
        info_refs_response = Base64.decode64(encoded_info_refs_response)

        resp = post(url, info_refs_response, headers)
        APIResponse.from_http_response(resp, primary_repo)
      rescue => e
        handle_exception(e)
      end

      private

      attr_reader :data

      def handle_exception(ex)
        case ex
        when MustBeASecondaryNode
          raise(ex)
        else
          FailedAPIResponse.from_exception(ex.message, primary_repo)
        end
      end

      def primary_repo
        @primary_repo ||= data['primary_repo']
      end

      def gl_id
        @gl_id ||= data['gl_id']
      end

      def base_headers
        @base_headers ||= {
          'Geo-GL-Id' => gl_id,
          'Authorization' => Gitlab::Geo::BaseRequest.new.authorization
        }
      end

      def get(url, headers)
        request(url, Net::HTTP::Get, headers)
      end

      def post(url, body, headers)
        request(url, Net::HTTP::Post, headers, body: body)
      end

      def request(url, klass, headers, body: nil)
        headers = base_headers.merge(headers)
        uri = URI.parse(url)
        req = klass.new(uri, headers)
        req.body = body if body

        http = Net::HTTP.new(uri.hostname, uri.port)
        http.read_timeout = HTTP_READ_TIMEOUT
        http.use_ssl = true if uri.is_a?(URI::HTTPS)

        http.start { http.request(req) }
      end

      def remove_http_service_fragment_from(body)
        # HTTP(S) and SSH responses are very similar, except for the fragment below.
        # As we're performing a git HTTP(S) request here, we'll get a HTTP(s)
        # suitable git response.  However, we're executing in the context of an
        # SSH session so we need to make the response suitable for what git over
        # SSH expects.
        #
        # See Downloading Data > HTTP(S) section at:
        # https://git-scm.com/book/en/v2/Git-Internals-Transfer-Protocols
        body.gsub(/\A001f# service=git-receive-pack\n0000/, '')
      end

      def ensure_secondary!
        raise MustBeASecondaryNode, 'Node is not a secondary or there is no primary Geo node' unless Gitlab::Geo.secondary_with_primary?
      end
    end
  end
end
