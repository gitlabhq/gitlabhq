# frozen_string_literal: true

module API
  module Entities
    class FeatureFlag < Grape::Entity
      class UserList < BasicUserList
        include RequestAwareEntity

        expose :project_id, documentation: { type: 'integer', example: 2 }
        expose :created_at, documentation: { type: 'dateTime', example: '2020-02-04T08:13:10.507Z' }
        expose :updated_at, documentation: { type: 'dateTime', example: '2020-02-04T08:13:10.507Z' }

        expose :path do |list|
          project_feature_flags_user_list_path(list.project, list)
        end

        expose :edit_path do |list|
          edit_project_feature_flags_user_list_path(list.project, list)
        end
      end
    end
  end
end
