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
end
