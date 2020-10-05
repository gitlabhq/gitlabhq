# frozen_string_literal: true

module API
  module Entities
    class FeatureFlag < Grape::Entity
      class UserList < Grape::Entity
        include RequestAwareEntity

        expose :id
        expose :iid
        expose :project_id
        expose :created_at
        expose :updated_at
        expose :name
        expose :user_xids

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
