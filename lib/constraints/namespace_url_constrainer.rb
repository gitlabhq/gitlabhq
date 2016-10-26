class NamespaceUrlConstrainer
  def matches?(request)
    id = request.path
    id = id.sub(/\A#{relative_url_root}/, '') if relative_url_root
    id = id.sub(/\A\/+/, '').split('/').first
    id = id.sub(/.atom\z/, '') if id

    if id =~ Gitlab::Regex.namespace_regex
      find_resource(id)
    end
  end

  def find_resource(id)
    Namespace.find_by_path(id)
  end

  private

  def relative_url_root
    if defined?(Gitlab::Application.config.relative_url_root)
      Gitlab::Application.config.relative_url_root
    end
  end
end
