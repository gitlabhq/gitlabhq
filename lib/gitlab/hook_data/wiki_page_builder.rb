# frozen_string_literal: true

module Gitlab
  module HookData
    class WikiPageBuilder < BaseBuilder
      alias_method :wiki_page, :object

      def build
        project_id = wiki_page.wiki.id
        return legacy_build unless Feature.enabled?(:wiki_content_background_job, Project.actor_from_id(project_id))

        wiki_page
          .attributes
          .except(:content)
          .merge(
            version_id: wiki_page.version&.id
          )
      end

      def page_content
        absolute_image_urls(wiki_page.content)
      end

      def uploads_prefix
        wiki_page.wiki.wiki_base_path
      end

      private

      def legacy_build
        wiki_page
          .attributes
          .merge(
            'content' => absolute_image_urls(wiki_page.content)
          )
      end
    end
  end
end
