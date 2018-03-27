module Gitlab
  module DataBuilder
    module WikiPage
      extend self

      def build(wiki_page, user, action)
        wiki = wiki_page.wiki

        {
          object_kind: wiki_page.class.name.underscore,
          user: user.hook_attrs,
          project: wiki.project.hook_attrs,
          wiki: wiki.hook_attrs,
          object_attributes: wiki_page.hook_attrs.merge(
            url: Gitlab::UrlBuilder.build(wiki_page),
            action: action
          )
        }
      end
    end
  end
end
