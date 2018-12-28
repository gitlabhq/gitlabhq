# frozen_string_literal: true

module API
  class GroupLabels < Grape::API
    include PaginationParams

    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get all labels of the group' do
        detail 'This feature was added in GitLab 11.7'
        success Entities::GroupLabel
      end
      params do
        use :pagination
      end
      get ':id/labels' do
        group_labels = available_labels_for(user_group)

        present paginate(group_labels), with: Entities::GroupLabel, current_user: current_user, parent: user_group
      end

      desc 'Create a new label' do
        detail 'This feature was added in GitLab 11.7'
        success Entities::GroupLabel
      end
      params do
        requires :name, type: String, desc: 'The name of the label to be created'
        requires :color, type: String, desc: "The color of the label given in 6-digit hex notation with leading '#' sign (e.g. #FFAABB) or one of the allowed CSS color names"
        optional :description, type: String, desc: 'The description of label to be created'
      end
      post ':id/labels' do
        authorize! :admin_label, user_group

        label = available_labels_for(user_group).find_by_title(params[:name])
        conflict!('Label already exists') if label

        label = ::Labels::CreateService.new(declared_params(include_missing: false)).execute(group: user_group)

        if label.persisted?
          present label, with: Entities::GroupLabel, current_user: current_user, parent: user_group
        else
          render_validation_error!(label)
        end
      end

      desc 'Delete an existing label' do
        detail 'This feature was added in GitLab 11.7'
        success Entities::GroupLabel
      end
      params do
        requires :name, type: String, desc: 'The name of the label to be deleted'
      end
      delete ':id/labels' do
        authorize! :admin_label, user_group

        label = find_label(user_group, params[:name])

        destroy_conditionally!(label)
      end

      desc 'Update an existing label. At least one optional parameter is required.' do
        detail 'This feature was added in GitLab 11.7'
        success Entities::GroupLabel
      end
      params do
        requires :name,  type: String, desc: 'The name of the label to be updated'
        optional :new_name, type: String, desc: 'The new name of the label'
        optional :color, type: String, desc: "The new color of the label given in 6-digit hex notation with leading '#' sign (e.g. #FFAABB) or one of the allowed CSS color names"
        optional :description, type: String, desc: 'The new description of label'
        at_least_one_of :new_name, :color, :description
      end
      put ':id/labels' do
        authorize! :admin_label, user_group

        label = find_label(user_group, params[:name])

        label = ::Labels::UpdateService.new(declared_params(include_missing: false)).execute(label)
        render_validation_error!(label) unless label.valid?

        present label, with: Entities::GroupLabel, current_user: current_user, parent: user_group
      end
    end
  end
end
