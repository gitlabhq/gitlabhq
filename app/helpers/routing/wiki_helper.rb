# frozen_string_literal: true

module Routing
  module WikiHelper
    def wiki_path(wiki, **options)
      Gitlab::UrlBuilder.wiki_url(wiki, only_path: true, **options)
    end

    def wiki_page_path(wiki, page, **options)
      Gitlab::UrlBuilder.wiki_page_url(wiki, page, only_path: true, **options)
    end

    def project_wiki_page_url(wiki_meta, **options)
      project_wiki_url(wiki_meta.project, wiki_meta.canonical_slug, **options)
    end

    def group_wiki_page_url(wiki_meta, **options)
      group_wiki_url(wiki_meta.namespace, wiki_meta.canonical_slug, **options)
    end
  end
end
