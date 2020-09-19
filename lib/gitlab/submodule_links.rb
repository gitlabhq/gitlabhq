# frozen_string_literal: true

module Gitlab
  class SubmoduleLinks
    include Gitlab::Utils::StrongMemoize

    Urls = Struct.new(:web, :tree, :compare)

    def initialize(repository)
      @repository = repository
      @cache_store = {}
    end

    def for(submodule, sha, diff_file = nil)
      submodule_url = submodule_url_for(sha, submodule.path)
      old_submodule_id = old_submodule_id(submodule_url, diff_file)
      urls = SubmoduleHelper.submodule_links_for_url(submodule.id, submodule_url, repository, old_submodule_id)
      Urls.new(*urls) if urls.any?
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

    def old_submodule_id(submodule_url, diff_file)
      return unless diff_file&.old_blob && diff_file&.old_content_sha

      # if the submodule url has changed from old_sha to sha, a compare link does not make sense
      #
      old_submodule_url = submodule_url_for(diff_file.old_content_sha, diff_file.old_blob.path)

      diff_file.old_blob.id if old_submodule_url == submodule_url
    end
  end
end
