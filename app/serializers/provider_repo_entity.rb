# frozen_string_literal: true

class ProviderRepoEntity < Grape::Entity
  include ImportHelper

  expose :id
  expose :full_name
  expose :owner_name do |provider_repo, options|
    owner_name(provider_repo, options[:provider])
  end

  expose :sanitized_name do |provider_repo|
    sanitize_project_name(provider_repo[:name])
  end

  expose :provider_link do |provider_repo, options|
    provider_project_link_url(options[:provider_url], provider_repo[:full_name])
  end

  private

  def owner_name(provider_repo, provider)
    provider_repo.dig(:owner, :login) if provider == :github
  end
end
