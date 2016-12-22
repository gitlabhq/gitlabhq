module ImportHelper
  def import_project_target(owner, name)
    namespace = current_user.can_create_group? ? owner : current_user.namespace_path
    "#{namespace}/#{name}"
  end

  def provider_project_link(provider, path_with_namespace)
    url = __send__("#{provider}_project_url", path_with_namespace)

    link_to path_with_namespace, url, target: '_blank'
  end

  private

  def github_project_url(path_with_namespace)
    "#{github_root_url}/#{path_with_namespace}"
  end

  def github_root_url
    return @github_url if defined?(@github_url)

    provider = Gitlab.config.omniauth.providers.find { |p| p.name == 'github' }
    @github_url = provider.fetch('url', 'https://github.com') if provider
  end

  def gitea_project_url(path_with_namespace)
    "#{@gitea_host_url.sub(%r{/+\z}, '')}/#{path_with_namespace}"
  end
end
