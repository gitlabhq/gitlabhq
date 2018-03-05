module ImportHelper
  def import_project_target(owner, name)
    namespace = current_user.can_create_group? ? owner : current_user.namespace_path
    "#{namespace}/#{name}"
  end

  def provider_project_link(provider, full_path)
    url = __send__("#{provider}_project_url", full_path) # rubocop:disable GitlabSecurity/PublicSend

    link_to full_path, url, target: '_blank', rel: 'noopener noreferrer'
  end

  private

  def github_project_url(full_path)
    "#{github_root_url}/#{full_path}"
  end

  def github_root_url
    return @github_url if defined?(@github_url)

    provider = Gitlab.config.omniauth.providers.find { |p| p.name == 'github' }
    @github_url = provider.fetch('url', 'https://github.com') if provider
  end

  def gitea_project_url(full_path)
    "#{@gitea_host_url.sub(%r{/+\z}, '')}/#{full_path}"
  end
end
