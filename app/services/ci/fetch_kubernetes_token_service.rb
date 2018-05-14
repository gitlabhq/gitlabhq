##
# TODO:
# Almost components in this class were copied from app/models/project_services/kubernetes_service.rb
# We should dry up those classes not to repeat the same code.
# Maybe we should have a special facility (e.g. lib/kubernetes_api) to maintain all Kubernetes API caller.
module Ci
  class FetchKubernetesTokenService
    attr_reader :api_url, :ca_pem, :username, :password

    def initialize(api_url, ca_pem, username, password)
      @api_url = api_url
      @ca_pem = ca_pem
      @username = username
      @password = password
    end

    def execute
      read_secrets.each do |secret|
        name = secret.dig('metadata', 'name')
        if /default-token/ =~ name
          token_base64 = secret.dig('data', 'token')
          return Base64.decode64(token_base64) if token_base64
        end
      end

      nil
    end

    private

    def read_secrets
      kubeclient = build_kubeclient!

      kubeclient.get_secrets.as_json
    rescue Kubeclient::HttpError => err
      raise err unless err.error_code == 404

      []
    end

    def build_kubeclient!(api_path: 'api', api_version: 'v1')
      raise "Incomplete settings" unless api_url && username && password

      ::Kubeclient::Client.new(
        join_api_url(api_path),
        api_version,
        auth_options: { username: username, password: password },
        ssl_options: kubeclient_ssl_options,
        http_proxy_uri: ENV['http_proxy']
      )
    end

    def join_api_url(api_path)
      url = URI.parse(api_url)
      prefix = url.path.sub(%r{/+\z}, '')

      url.path = [prefix, api_path].join("/")

      url.to_s
    end

    def kubeclient_ssl_options
      opts = { verify_ssl: OpenSSL::SSL::VERIFY_PEER }

      if ca_pem.present?
        opts[:cert_store] = OpenSSL::X509::Store.new
        opts[:cert_store].add_cert(OpenSSL::X509::Certificate.new(ca_pem))
      end

      opts
    end
  end
end
