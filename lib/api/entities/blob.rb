# frozen_string_literal: true

module API
  module Entities
    class Blob < Grape::Entity
      expose :basename, documentation: { type: 'String', example: 'README' }
      expose :data, documentation: { type: 'String', example: "---\ntitle: Page\n---" }
      expose :path, documentation: { type: 'String', example: 'README.md' }
      # TODO: :filename was renamed to :path but both still return the full path,
      # in the future we can only return the filename here without the leading
      # directory path.
      # https://gitlab.com/gitlab-org/gitlab/issues/34521
      expose :path, as: :filename, documentation: { type: 'String', example: 'README.md' }
      expose :id, documentation: { type: 'String', example: '2695effb5807a22ff3d138d593fd856244e155e7' }
      expose :ref, documentation: { type: 'String', example: 'main' }
      expose :startline, documentation: { type: 'Integer', example: 1 }
      expose :project_id, documentation: { type: 'Integer', example: 1 }
      expose :group_id,
        documentation: { type: 'Integer', example: 1 },
        if: ->(object) { object.is_a?(Gitlab::Search::FoundWikiPage) }

      private

      def group_id
        object.group&.id
      end
    end
  end
end
