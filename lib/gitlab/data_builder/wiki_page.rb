# frozen_string_literal: true

module Gitlab
  module DataBuilder
    module WikiPage
      extend self

      def build(wiki_page, user, action)
        wiki = wiki_page.wiki

        # TODO: group hooks https://gitlab.com/gitlab-org/gitlab/-/issues/216904
        return {} if wiki.container.is_a?(Group)

        {
          object_kind: wiki_page.class.name.underscore,
          user: user.hook_attrs,
          project: wiki.project.hook_attrs,
          wiki: wiki.hook_attrs,
          object_attributes: wiki_page.hook_attrs.merge(
            url: Gitlab::UrlBuilder.build(wiki_page),
            action: action,
            diff_url: Gitlab::UrlBuilder.build(wiki_page, action: :diff, version_id: wiki_page.version.id)
          )
        }
      end
    end
  end
end
