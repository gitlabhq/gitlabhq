# frozen_string_literal: true

module API
  class GroupLabels < Grape::API
    include PaginationParams
    helpers ::API::Helpers::LabelHelpers

    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get all labels of the group' do
        detail 'This feature was added in GitLab 11.8'
        success Entities::GroupLabel
      end
      params do
        optional :with_counts, type: Boolean, default: false,
                 desc: 'Include issue and merge request counts'
        use :pagination
      end
      get ':id/labels' do
        get_labels(user_group, Entities::GroupLabel)
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
        detail 'This feature was added in GitLab 11.8'
        success Entities::GroupLabel
      end
      params do
        requires :name, type: String, desc: 'The name of the label to be updated'
        optional :new_name, type: String, desc: 'The new name of the label'
        optional :color, type: String, desc: "The new color of the label given in 6-digit hex notation with leading '#' sign (e.g. #FFAABB) or one of the allowed CSS color names"
        optional :description, type: String, desc: 'The new description of label'
        at_least_one_of :new_name, :color, :description
      end
      put ':id/labels' do
        update_label(user_group, Entities::GroupLabel)
      end

      desc 'Delete an existing label' do
        detail 'This feature was added in GitLab 11.8'
        success Entities::GroupLabel
      end
      params do
        requires :name, type: String, desc: 'The name of the label to be deleted'
      end
      delete ':id/labels' do
        delete_label(user_group)
      end
    end
  end
end
