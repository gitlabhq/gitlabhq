# frozen_string_literal: true

module BulkImports
  module Common
    module Pipelines
      class BadgesPipeline
        include Pipeline
        include HexdigestCacheStrategy

        extractor BulkImports::Common::Extractors::RestExtractor,
          query: BulkImports::Common::Rest::GetBadgesQuery

        transformer Common::Transformers::ProhibitedAttributesTransformer

        def transform(context, data)
          return if data.blank?
          # Project badges API returns badges of both group and project kind. To avoid creation of duplicates for the group we skip group badges when it's a project.
          return if context.entity.project? && group_badge?(data)

          {
            name: data['name'],
            link_url: data['link_url'],
            image_url: data['image_url']
          }
        end

        def load(context, data)
          return if data.blank?

          if context.entity.project?
            context.portable.project_badges.create!(data)
          else
            context.portable.badges.create!(data)
          end
        end

        private

        def group_badge?(data)
          data['kind'] == 'group'
        end
      end
    end
  end
end
