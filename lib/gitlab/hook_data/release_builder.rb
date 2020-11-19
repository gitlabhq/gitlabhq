# frozen_string_literal: true

module Gitlab
  module HookData
    class ReleaseBuilder < BaseBuilder
      def self.safe_hook_attributes
        %i[
          id
          created_at
          description
          name
          released_at
          tag
        ].freeze
      end

      alias_method :release, :object

      def build(action)
        attrs = {
          object_kind: object_kind,
          project: release.project.hook_attrs,
          description: absolute_image_urls(release.description),
          url: Gitlab::UrlBuilder.build(release),
          action: action,
          assets: {
              count: release.assets_count,
              links: release.links.map(&:hook_attrs),
              sources: release.sources.map(&:hook_attrs)
          },
          commit: release.commit.hook_attrs
        }

        release.attributes.with_indifferent_access.slice(*self.class.safe_hook_attributes)
          .merge!(attrs)
      end

      private

      def object_kind
        release.class.name.underscore
      end
    end
  end
end
