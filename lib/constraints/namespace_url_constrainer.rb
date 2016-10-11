class NamespaceUrlConstrainer
  def matches?(request)
    id = request.path.sub(/\A\/+/, '').split('/').first.sub(/.atom\z/, '')

    if id =~ Gitlab::Regex.namespace_regex
      find_resource(id)
    end
  end

  def find_resource(id)
    Namespace.find_by_path(id)
  end
end
