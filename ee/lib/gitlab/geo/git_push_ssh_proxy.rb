# frozen_string_literal: true

module Gitlab
  module Geo
    class GitPushSSHProxy
      HTTP_READ_TIMEOUT = 10
      HTTP_SUCCESS_CODE = '200'.freeze

      MustBeASecondaryNode = Class.new(StandardError)

      def initialize(data)
        @data = data
      end

      def info_refs
        ensure_secondary!

        url = "#{primary_repo}/info/refs?service=git-receive-pack"
        headers = {
          'Content-Type' => 'application/x-git-upload-pack-request'
        }

        resp = get(url, headers)
        return resp unless resp.code == HTTP_SUCCESS_CODE

        resp.body = remove_http_service_fragment_from(resp.body)

        resp
      end

      def push(info_refs_response)
        ensure_secondary!

        url = "#{primary_repo}/git-receive-pack"
        headers = {
          'Content-Type' => 'application/x-git-receive-pack-request',
          'Accept' => 'application/x-git-receive-pack-result'
        }

        post(url, info_refs_response, headers)
      end

      private

      attr_reader :data

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
