module ImportHelper
  def github_project_link(path_with_namespace)
    link_to path_with_namespace, github_project_url(path_with_namespace), target: '_blank'
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
end
