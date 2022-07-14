# frozen_string_literal: true

module Integrations
  module HarborSerializers
    class ArtifactEntity < Grape::Entity
      include ActionView::Helpers::SanitizeHelper

      expose :harbor_id do |item|
        item['id']
      end

      expose :digest do |item|
        strip_tags(item['digest'])
      end

      expose :size do |item|
        item['size']
      end

      expose :push_time do |item|
        item['push_time']&.to_datetime&.utc
      end

      expose :tags do |item|
        item['tags'].map { |tag| strip_tags(tag['name']) }
      end
    end
  end
end
