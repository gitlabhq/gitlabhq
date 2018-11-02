class Kubeclient::Client
  # We need to monkey patch this method until
  # https://github.com/abonas/kubeclient/pull/323 is merged
  def proxy_url(kind, name, port, namespace = '')
    discover unless @discovered
    entity_name_plural =
      if %w[services pods nodes].include?(kind.to_s)
        kind.to_s
      else
        @entities[kind.to_s].resource_name
      end

    ns_prefix = build_namespace_prefix(namespace)
    rest_client["#{ns_prefix}#{entity_name_plural}/#{name}:#{port}/proxy"].url
  end

  # Monkey patch to set `max_redirects: 0`, so that kubeclient
  # does not follow redirects and expose internal services.
  # See https://gitlab.com/gitlab-org/gitlab-ce/issues/53158
  def create_rest_client(path = nil)
    path ||= @api_endpoint.path
    options = {
      ssl_ca_file: @ssl_options[:ca_file],
      ssl_cert_store: @ssl_options[:cert_store],
      verify_ssl: @ssl_options[:verify_ssl],
      ssl_client_cert: @ssl_options[:client_cert],
      ssl_client_key: @ssl_options[:client_key],
      proxy: @http_proxy_uri,
      user: @auth_options[:username],
      password: @auth_options[:password],
      open_timeout: @timeouts[:open],
      read_timeout: @timeouts[:read],
      max_redirects: 0
    }
    RestClient::Resource.new(@api_endpoint.merge(path).to_s, options)
  end
end
