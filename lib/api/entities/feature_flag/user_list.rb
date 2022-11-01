# frozen_string_literal: true

module API
  module Entities
    class FeatureFlag < Grape::Entity
      class UserList < Grape::Entity
        include RequestAwareEntity

        expose :id, documentation: { type: 'integer', example: 1 }
        expose :iid, documentation: { type: 'integer', example: 1 }
        expose :project_id, documentation: { type: 'integer', example: 2 }
        expose :created_at, documentation: { type: 'dateTime', example: '2020-02-04T08:13:10.507Z' }
        expose :updated_at, documentation: { type: 'dateTime', example: '2020-02-04T08:13:10.507Z' }
        expose :name, documentation: { type: 'string', example: 'user_list' }
        expose :user_xids, documentation: { type: 'string', example: 'user1,user2' }

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
