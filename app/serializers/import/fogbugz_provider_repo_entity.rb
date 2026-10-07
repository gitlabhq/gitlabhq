# frozen_string_literal: true

class Import::FogbugzProviderRepoEntity < Import::BaseProviderRepoEntity
  include ImportHelper

  expose :full_name, override: true, &:name

  expose :sanitized_name, override: true, &:safe_name

  expose :provider_link, override: true do |repo, options|
    provider_project_link_url(options[:provider_url], repo.path)
  end
end
