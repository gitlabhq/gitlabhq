# frozen_string_literal: true

module API
  class Labels < Grape::API
    include PaginationParams
    helpers ::API::Helpers::LabelHelpers

    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get all labels of the project' do
        success Entities::ProjectLabel
      end
      params do
        optional :with_counts, type: Boolean, default: false,
                 desc: 'Include issue and merge request counts'
        use :pagination
      end
      get ':id/labels' do
        get_labels(user_project, Entities::ProjectLabel)
      end

      desc 'Create a new label' do
        success Entities::ProjectLabel
      end
      params do
        use :label_create_params
        optional :priority, type: Integer, desc: 'The priority of the label', allow_blank: true
      end
      post ':id/labels' do
        create_label(user_project, Entities::ProjectLabel)
      end

      desc 'Update an existing label. At least one optional parameter is required.' do
        success Entities::ProjectLabel
      end
      params do
        optional :label_id, type: Integer, desc: 'The id of the label to be updated'
        optional :name, type: String, desc: 'The name of the label to be updated'
        optional :new_name, type: String, desc: 'The new name of the label'
        optional :color, type: String, desc: "The new color of the label given in 6-digit hex notation with leading '#' sign (e.g. #FFAABB) or one of the allowed CSS color names"
        optional :description, type: String, desc: 'The new description of label'
        optional :priority, type: Integer, desc: 'The priority of the label', allow_blank: true
        exactly_one_of :label_id, :name
        at_least_one_of :new_name, :color, :description, :priority
      end
      put ':id/labels' do
        update_label(user_project, Entities::ProjectLabel)
      end

      desc 'Delete an existing label' do
        success Entities::ProjectLabel
      end
      params do
        optional :label_id, type: Integer, desc: 'The id of the label to be deleted'
        optional :name, type: String, desc: 'The name of the label to be deleted'
        exactly_one_of :label_id, :name
      end
      delete ':id/labels' do
        delete_label(user_project)
      end
    end
  end
end
