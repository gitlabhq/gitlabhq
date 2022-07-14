# frozen_string_literal: true

module Integrations
  module HarborSerializers
    class TagEntity < Grape::Entity
      include ActionView::Helpers::SanitizeHelper

      expose :harbor_repository_id do |item|
        item['repository_id']
      end

      expose :harbor_artifact_id do |item|
        item['artifact_id']
      end

      expose :harbor_id do |item|
        item['id']
      end

      expose :name do |item|
        strip_tags(item['name'])
      end

      expose :pull_time do |item|
        item['pull_time']&.to_datetime&.utc
      end

      expose :push_time do |item|
        item['push_time']&.to_datetime&.utc
      end

      expose :signed do |item|
        item['signed']
      end

      expose :immutable do |item|
        item['immutable']
      end
    end
  end
end
