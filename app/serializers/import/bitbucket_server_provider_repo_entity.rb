# frozen_string_literal: true

class Import::BitbucketServerProviderRepoEntity < Import::BitbucketProviderRepoEntity
  expose :provider_link, override: true do |repo, options|
    repo.browse_url
  end
end
