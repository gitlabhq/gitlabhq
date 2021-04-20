# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class BadgesPipeline
        include Pipeline

        extractor BulkImports::Common::Extractors::RestExtractor,
          query: BulkImports::Groups::Rest::GetBadgesQuery

        transformer Common::Transformers::ProhibitedAttributesTransformer

        def transform(_, data)
          return if data.blank?

          {
            name: data['name'],
            link_url: data['link_url'],
            image_url: data['image_url']
          }
        end

        def load(context, data)
          return if data.blank?

          context.group.badges.create!(data)
        end
      end
    end
  end
end
