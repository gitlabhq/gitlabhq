# frozen_string_literal: true

module Integrations
  module HarborSerializers
    class RepositoryEntity < Grape::Entity
      include ActionView::Helpers::SanitizeHelper

      expose :harbor_id do |item|
        item['id']
      end

      expose :name do |item|
        validate_path(item['name']).then { |name| strip_tags(name) }
      end

      expose :artifact_count do |item|
        item['artifact_count']
      end

      expose :creation_time do |item|
        item['creation_time']&.to_datetime&.utc
      end

      expose :update_time do |item|
        item['update_time']&.to_datetime&.utc
      end

      expose :harbor_project_id do |item|
        item['project_id']
      end

      expose :pull_count do |item|
        item['pull_count']
      end

      expose :location do |item|
        path = [
          'harbor/projects',
          item['project_id'].to_s,
          'repositories',
          item['name'].remove("#{options[:project_name]}/")
        ].join('/')
        path = validate_path(path)
        strip_tags(Gitlab::Utils.append_path(options[:url], path))
      end

      private

      def validate_path(path)
        Gitlab::PathTraversal.check_path_traversal!(path)
      rescue ::Gitlab::PathTraversal::PathTraversalAttackError
        Gitlab::AppLogger.error("Path traversal attack detected #{path}")
        ''
      end
    end
  end
end
