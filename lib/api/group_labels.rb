# frozen_string_literal: true

module API
  class GroupLabels < ::API::Base
    include PaginationParams

    helpers ::API::Helpers::LabelHelpers

    before { authenticate! }

    feature_category :team_planning
    urgency :low

    params do
      requires :id, type: String, desc: 'ID or URL-encoded path of the group.'
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
          desc: 'If `true`, includes issue and merge request counts.'
        optional :include_ancestor_groups,
          type: Boolean,
          default: true,
          desc: 'If `true`, includes ancestor groups.'
        optional :include_descendant_groups,
          type: Boolean,
          default: false,
          desc: 'If `true`, includes descendant groups.'
        optional :only_group_labels,
          type: Boolean,
          default: true,
          desc: 'If `true`, returns only group labels. If `false`, also returns project labels.'
        optional :search,
          type: String,
          desc: 'Keyword to filter labels by.'
        optional :archived, type: Boolean,
          desc: 'If `true`, returns only archived labels. If `false`, returns only non-archived labels. ' \
            'If omitted, returns all labels. Introduced in GitLab 18.10.'
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
        requires :name, types: [String, Integer], desc: 'ID or name of the label.'
        optional :include_ancestor_groups,
          type: Boolean,
          default: true,
          desc: 'If `true`, includes ancestor groups.'
        optional :include_descendant_groups,
          type: Boolean,
          default: false,
          desc: 'If `true`, includes descendant groups.'
        optional :only_group_labels,
          type: Boolean,
          default: true,
          desc: 'If `true`, returns only group labels. If `false`, also returns project labels.'
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
        optional :label_id, type: Integer, desc: 'ID of the label to update.'
        optional :name, type: String, desc: 'Name of the label to update.'
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
        requires :name, type: String, desc: 'Name of the label to delete.'
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
        requires :name, type: String, desc: 'Name or ID of the label to update.'
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
        requires :name, type: String, desc: 'Name or ID of the label to delete.'
      end
      route_setting :authorization, permissions: :delete_label, boundary_type: :group
      delete ':id/labels/:name' do
        delete_label(user_group)
      end
    end
  end
end
