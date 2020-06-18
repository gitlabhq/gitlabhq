# frozen_string_literal: true

class Import::GitlabProviderRepoEntity < Import::BaseProviderRepoEntity
  expose :id, override: true do |repo|
    repo["id"]
  end

  expose :full_name, override: true do |repo|
    repo["path_with_namespace"]
  end

  expose :sanitized_name, override: true do |repo|
    repo["path"]
  end

  expose :provider_link, override: true do |repo|
    repo["web_url"]
  end
end
