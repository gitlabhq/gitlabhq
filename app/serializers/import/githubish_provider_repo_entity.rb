# frozen_string_literal: true

class Import::GithubishProviderRepoEntity < Import::BaseProviderRepoEntity
  include ImportHelper

  expose :sanitized_name, override: true do |provider_repo|
    sanitize_project_name(provider_repo[:name])
  end

  expose :provider_link, override: true do |provider_repo, options|
    provider_project_link_url(options[:provider_url], provider_repo[:full_name])
  end

  private

  def owner_name(provider_repo, provider)
    provider_repo.dig(:owner, :login) if provider == :github
  end
end
