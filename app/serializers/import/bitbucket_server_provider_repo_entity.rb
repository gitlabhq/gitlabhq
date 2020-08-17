# frozen_string_literal: true

class Import::BitbucketServerProviderRepoEntity < Import::BitbucketProviderRepoEntity
  expose :id, override: true do |repo|
    "#{repo.project_key}/#{repo.slug}"
  end

  expose :provider_link, override: true do |repo, options|
    repo.browse_url
  end
end
