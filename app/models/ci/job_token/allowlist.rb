# frozen_string_literal: true
module Ci
  module JobToken
    class Allowlist
      def initialize(source_project, direction:)
        @source_project = source_project
        @direction = direction
      end

      def includes?(target_project)
        source_links
          .with_target(target_project)
          .exists?
      end

      def projects
        Project.from_union(target_projects, remove_duplicates: false)
      end

      def add!(target_project, user:)
        Ci::JobToken::ProjectScopeLink.create!(
          source_project: @source_project,
          direction: @direction,
          target_project: target_project,
          added_by: user
        )
      end

      private

      def source_links
        Ci::JobToken::ProjectScopeLink
          .with_source(@source_project)
          .where(direction: @direction)
      end

      def target_project_ids
        source_links
          # pluck needed to avoid ci and main db join
          .pluck(:target_project_id)
      end

      def target_projects
        [
          Project.id_in(@source_project),
          Project.id_in(target_project_ids)
        ]
      end
    end
  end
end
