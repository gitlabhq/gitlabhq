# frozen_string_literal: true

module Todos
  module Destroy
    class PrivateFeaturesService < ::Todos::Destroy::BaseService
      attr_reader :project_ids, :user_id

      def initialize(project_ids, user_id = nil)
        @project_ids = project_ids
        @user_id = user_id
      end

      def execute
        ProjectFeature.where(project_id: project_ids).each do |project_features|
          target_types = []
          target_types << Issue if private?(project_features.issues_access_level)
          target_types << MergeRequest if private?(project_features.merge_requests_access_level)
          target_types << Commit if private?(project_features.repository_access_level)

          next if target_types.empty?

          remove_todos(project_features.project_id, target_types)
        end
      end

      private

      def private?(feature_level)
        feature_level == ProjectFeature::PRIVATE
      end

      def remove_todos(project_id, target_types)
        items = Todo.where(project_id: project_id)
        items = items.where(user_id: user_id) if user_id

        items.where('user_id NOT IN (?)', authorized_users)
          .where(target_type: target_types)
          .delete_all
      end
    end
  end
end
