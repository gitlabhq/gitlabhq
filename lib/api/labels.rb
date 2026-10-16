# frozen_string_literal: true

module API
  class Labels < ::API::Base
    include PaginationParams
    include APIGuard

    helpers ::API::Helpers::LabelHelpers

    allow_access_with_scope :ai_workflows, if: ->(request) { request.get? || request.head? }

    before { authenticate! }

    feature_category :team_planning
    urgency :low

    LABEL_ENDPOINT_REQUIREMENTS = ::API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(
      name: ::API::NO_SLASH_URL_PART_REGEX,
      label_id: ::API::NO_SLASH_URL_PART_REGEX).freeze

    params do
      requires :id, types: [String, Integer], desc: 'ID or URL-encoded path of the project.'
    end
    resource :projects, requirements: LABEL_ENDPOINT_REQUIREMENTS do
      desc 'List all project labels' do
        detail 'Lists all labels for a specified project. By default, this request returns 20 results at a time ' \
          'because the API results are paginated.'
        success Entities::ProjectLabel
        tags ['labels']
      end
      params do
        optional :with_counts, type: Boolean, default: false,
          desc: 'If `true`, includes issue and merge request counts.'
        optional :include_ancestor_groups, type: Boolean, default: true,
          desc: 'If `true`, includes ancestor groups.'
        optional :search, type: String,
          desc: 'Keyword to filter labels by.'
        optional :archived, type: Boolean,
          desc: 'If `true`, returns only archived labels. If `false`, returns only non-archived labels. ' \
            'If omitted, returns all labels. Introduced in GitLab 18.10.'

        use :pagination
      end
      route_setting :authorization, permissions: :read_label, boundary_type: :project
      get ':id/labels' do
        get_labels(user_project, Entities::ProjectLabel, declared_params)
      end

      desc 'Retrieve a project label' do
        detail 'Retrieves a specified label for a project.'
        success Entities::ProjectLabel
        tags ['labels']
      end
      params do
        requires :name, types: [String, Integer], desc: 'ID or name of the label.'
        optional :include_ancestor_groups, type: Boolean, default: true,
          desc: 'If `true`, includes ancestor groups.'
      end
      route_setting :authorization, permissions: :read_label, boundary_type: :project
      get ':id/labels/:name' do
        get_label(user_project, Entities::ProjectLabel, declared_params)
      end

      desc 'Create a project label' do
        detail 'Creates a label for a specified project.'
        success Entities::ProjectLabel
        tags ['labels']
      end
      params do
        use :label_create_params
        optional :priority, type: Integer, desc: 'The priority of the label', allow_blank: true
      end
      route_setting :authorization, permissions: :create_label, boundary_type: :project
      post ':id/labels' do
        create_label(user_project, Entities::ProjectLabel)
      end

      desc 'Update an existing label. At least one optional parameter is required.' do
        detail 'Deprecated in GitLab 12.4. Use PUT /projects/:id/labels/:name instead.'
        deprecated true
        success Entities::ProjectLabel
        tags ['labels']
      end
      params do
        optional :label_id, type: Integer, desc: 'ID of the label to update.'
        optional :name, type: String, desc: 'Name of the label to update.'
        use :project_label_update_params
        exactly_one_of :label_id, :name
      end
      route_setting :authorization, permissions: :update_label, boundary: -> { label_update_boundary },
        boundaries: [{ boundary_type: :project }, { boundary_type: :group }]
      put ':id/labels' do
        update_label(user_project, Entities::ProjectLabel)
      end

      desc 'Delete an existing label' do
        detail 'Deprecated in GitLab 12.4. Use DELETE /projects/:id/labels/:name instead.'
        deprecated true
        success Entities::ProjectLabel
        tags ['labels']
      end
      params do
        optional :label_id, type: Integer, desc: 'ID of the label to delete.'
        optional :name, type: String, desc: 'Name of the label to delete.'
        exactly_one_of :label_id, :name
      end
      route_setting :authorization, permissions: :delete_label, boundary: -> { label_owner_boundary },
        boundaries: [{ boundary_type: :project }, { boundary_type: :group }]
      delete ':id/labels' do
        delete_label(user_project)
      end

      desc 'Promote a label to a group label' do
        detail 'Added in GitLab 12.3 and deprecated in GitLab 12.4. ' \
          'Use PUT /projects/:id/labels/:name/promote instead.'
        deprecated true
        success Entities::GroupLabel
        tags ['labels']
      end
      params do
        requires :name, type: String, desc: 'Name of the label to promote.'
      end
      route_setting :authorization, permissions: :promote_label, boundary_type: :project
      put ':id/labels/promote' do
        promote_label(user_project)
      end

      desc 'Update a project label' do
        detail 'Updates a specified label for a project with a different name or color. At least one parameter is ' \
          'required to update the label.'
        success Entities::ProjectLabel
        tags ['labels']
      end
      params do
        requires :name, type: String, desc: 'Name or ID of the label to update.'
        use :project_label_update_params
      end
      route_setting :authorization, permissions: :update_label, boundary: -> { label_update_boundary },
        boundaries: [{ boundary_type: :project }, { boundary_type: :group }]
      put ':id/labels/:name' do
        update_label(user_project, Entities::ProjectLabel)
      end

      desc 'Delete a project label' do
        detail 'Deletes a specified label from a project.'
        success Entities::ProjectLabel
        tags ['labels']
      end
      params do
        requires :name, type: String, desc: 'Name or ID of the label to delete.'
      end
      route_setting :authorization, permissions: :delete_label, boundary: -> { label_owner_boundary },
        boundaries: [{ boundary_type: :project }, { boundary_type: :group }]
      delete ':id/labels/:name' do
        delete_label(user_project)
      end

      desc 'Promote a project label to a group label' do
        detail 'Promotes a specified project label to a group label. The label keeps its ID.'
        success Entities::GroupLabel
        tags ['labels']
      end
      params do
        requires :name, type: String, desc: 'Name or ID of the label to promote.'
      end
      route_setting :authorization, permissions: :promote_label, boundary_type: :project
      put ':id/labels/:name/promote' do
        promote_label(user_project)
      end
    end
  end
end
