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
      desc 'List all group labels' do
        detail 'Lists all group labels for a specified group.'
        success Entities::GroupLabel
        tags ['labels']
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
        optional :archived, type: Boolean,
          desc: 'Filter by archived status. This feature was added in GitLab 18.10'
        use :pagination
      end
      route_setting :authorization, permissions: :read_label, boundary_type: :group
      get ':id/labels' do
        get_labels(user_group, Entities::GroupLabel, declared_params)
      end

      desc 'Retrieve a group label' do
        detail 'Retrieves a specified group label.'
        success Entities::GroupLabel
        tags ['labels']
      end
      params do
        requires :name, types: [String, Integer], desc: 'The ID or name of a label'
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
      route_setting :authorization, permissions: :read_label, boundary_type: :group
      get ':id/labels/:name' do
        get_label(user_group, Entities::GroupLabel, declared_params)
      end

      desc 'Create a group label' do
        detail 'Creates a group label.'
        success Entities::GroupLabel
        tags ['labels']
      end
      params do
        use :label_create_params
      end
      route_setting :authorization, permissions: :create_label, boundary_type: :group
      post ':id/labels' do
        create_label(user_group, Entities::GroupLabel)
      end

      desc 'Update a group label' do
        detail 'Updates an existing group label. At least one parameter is required to update the group label.'
        success Entities::GroupLabel
        tags ['labels']
      end
      params do
        optional :label_id, type: Integer, desc: 'The ID of the label to be updated'
        optional :name, type: String, desc: 'The name of the label to be updated'
        use :group_label_update_params
        exactly_one_of :label_id, :name
      end
      route_setting :authorization, permissions: :update_label, boundary_type: :group
      put ':id/labels' do
        update_label(user_group, Entities::GroupLabel)
      end

      desc 'Delete a group label' do
        detail 'Deletes a specified group label.'
        success Entities::GroupLabel
        tags ['labels']
      end
      params do
        requires :name, type: String, desc: 'The name of the label to be deleted'
      end
      route_setting :authorization, permissions: :delete_label, boundary_type: :group
      delete ':id/labels' do
        delete_label(user_group)
      end

      desc 'Update a group label' do
        detail 'Updates a specified group label. At least one parameter is required to update the group label.'
        success Entities::GroupLabel
        tags ['labels']
      end
      params do
        requires :name, type: String, desc: 'The name or id of the label to be updated'
        use :group_label_update_params
      end
      route_setting :authorization, permissions: :update_label, boundary_type: :group
      put ':id/labels/:name' do
        update_label(user_group, Entities::GroupLabel)
      end

      desc 'Delete a group label' do
        detail 'Deletes a specified group label.'
        success Entities::GroupLabel
        tags ['labels']
      end
      params do
        requires :name, type: String, desc: 'The name or id of the label to be deleted'
      end
      route_setting :authorization, permissions: :delete_label, boundary_type: :group
      delete ':id/labels/:name' do
        delete_label(user_group)
      end
    end
  end
end
