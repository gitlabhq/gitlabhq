# frozen_string_literal: true

module Gitlab
  class SubmoduleLinks
    include Gitlab::Utils::StrongMemoize

    def initialize(repository)
      @repository = repository
      @cache_store = {}
    end

    def for(submodule, sha)
      submodule_url = submodule_url_for(sha, submodule.path)
      SubmoduleHelper.submodule_links_for_url(submodule.id, submodule_url, repository)
    end

    private

    attr_reader :repository

    def submodule_urls_for(sha)
      @cache_store.fetch(sha) do
        submodule_urls = repository.submodule_urls_for(sha)
        @cache_store[sha] = submodule_urls
      end
    end

    def submodule_url_for(sha, path)
      urls = submodule_urls_for(sha)
      urls && urls[path]
    end
  end
end
