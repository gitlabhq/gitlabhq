# frozen_string_literal: true

module API
  class GroupLabels < ::API::Base
    include PaginationParams
    helpers ::API::Helpers::LabelHelpers

    before { authenticate! }

    feature_category :team_planning
    urgency :low

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: ::API::Labels::LABEL_ENDPOINT_REQUIREMENTS do
      desc 'Get all labels of the group' do
        detail 'This feature was added in GitLab 11.8'
        success Entities::GroupLabel
      end
      params do
        optional :with_counts,
          type: Boolean,
          default: false,
          desc: 'Include issue and merge request counts'
        optional :include_ancestor_groups,
          type: Boolean,
          default: true,
          desc: 'Include ancestor groups'
        optional :include_descendant_groups,
          type: Boolean,
          default: false,
          desc: 'Include descendant groups. This feature was added in GitLab 13.6'
        optional :only_group_labels,
          type: Boolean,
          default: true,
          desc: 'Toggle to include only group labels or also project labels. This feature was added in GitLab 13.6'
        optional :search,
          type: String,
          desc: 'Keyword to filter labels by. This feature was added in GitLab 13.6'
        use :pagination
      end
      get ':id/labels' do
        get_labels(user_group, Entities::GroupLabel, declared_params)
      end

      desc 'Get a single label' do
        detail 'This feature was added in GitLab 12.4.'
        success Entities::GroupLabel
      end
      params do
        optional :include_ancestor_groups,
          type: Boolean,
          default: true,
          desc: 'Include ancestor groups'
        optional :include_descendant_groups,
          type: Boolean,
          default: false,
          desc: 'Include descendant groups. This feature was added in GitLab 13.6'
        optional :only_group_labels,
          type: Boolean,
          default: true,
          desc: 'Toggle to include only group labels or also project labels. This feature was added in GitLab 13.6'
      end
      get ':id/labels/:name' do
        get_label(user_group, Entities::GroupLabel, declared_params)
      end

      desc 'Create a new label' do
        detail 'This feature was added in GitLab 11.8'
        success Entities::GroupLabel
      end
      params do
        use :label_create_params
      end
      post ':id/labels' do
        create_label(user_group, Entities::GroupLabel)
      end

      desc 'Update an existing label. At least one optional parameter is required.' do
        detail 'This feature was added in GitLab 11.8 and deprecated in GitLab 12.4.'
        success Entities::GroupLabel
      end
      params do
        optional :label_id, type: Integer, desc: 'The ID of the label to be updated'
        optional :name, type: String, desc: 'The name of the label to be updated'
        use :group_label_update_params
        exactly_one_of :label_id, :name
      end
      put ':id/labels' do
        update_label(user_group, Entities::GroupLabel)
      end

      desc 'Delete an existing label' do
        detail 'This feature was added in GitLab 11.8 and deprecated in GitLab 12.4.'
        success Entities::GroupLabel
      end
      params do
        requires :name, type: String, desc: 'The name of the label to be deleted'
      end
      delete ':id/labels' do
        delete_label(user_group)
      end

      desc 'Update an existing label. At least one optional parameter is required.' do
        detail 'This feature was added in GitLab 12.4.'
        success Entities::GroupLabel
      end
      params do
        requires :name, type: String, desc: 'The name or id of the label to be updated'
        use :group_label_update_params
      end
      put ':id/labels/:name' do
        update_label(user_group, Entities::GroupLabel)
      end

      desc 'Delete an existing label' do
        detail 'This feature was added in GitLab 12.4.'
        success Entities::GroupLabel
      end
      params do
        requires :name, type: String, desc: 'The name or id of the label to be deleted'
      end
      delete ':id/labels/:name' do
        delete_label(user_group)
      end
    end
  end
end
