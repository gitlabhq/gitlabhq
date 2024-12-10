# frozen_string_literal: true

module Integrations
  module HarborSerializers
    class ArtifactEntity < Grape::Entity
      include ActionView::Helpers::SanitizeHelper

      expose :harbor_id do |item|
        item['id']
      end

      expose :digest do |item|
        validate_path(item['digest']).then { |digest| strip_tags(digest) }
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

      private

      def validate_path(path)
        ::Gitlab::PathTraversal.check_path_traversal!(path)
      rescue ::Gitlab::PathTraversal::PathTraversalAttackError => e
        ::Gitlab::ErrorTracking.track_exception(
          e,
          message: "Path traversal attack detected #{path}",
          class: self.class.name
        )
        ''
      end
    end
  end
end
