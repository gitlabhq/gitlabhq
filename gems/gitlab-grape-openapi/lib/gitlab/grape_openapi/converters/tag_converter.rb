# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      class TagConverter
        attr_reader :api_class, :tag_registry

        def initialize(api_class, tag_registry)
          @api_class = api_class
          @tag_registry = tag_registry
        end

        def convert
          tags = build_tags(api_class)

          tags.each do |tag|
            tag_registry.register(tag)
          end
        end

        private

        def build_tags(api_class)
          tags = api_class.routes.flat_map do |route|
            route.settings.dig(:description, :tags)
          end.compact

          tags.map do |tag_name|
            Gitlab::GrapeOpenapi::Models::Tag.new(tag_name)
          end
        end
      end
    end
  end
end
