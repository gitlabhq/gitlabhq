# frozen_string_literal: true

module API
  class GroupAvatar < ::API::Base
    helpers Helpers::GroupsHelpers

    feature_category :subgroups

    resource :groups do
      desc 'Download the group avatar' do
        detail 'This feature was introduced in GitLab 14.0'
      end
      params do
        requires :id, type: String, desc: 'The group id'
      end
      get ':id/avatar' do
        present_carrierwave_file!(user_group.avatar)
      end
    end
  end
end
