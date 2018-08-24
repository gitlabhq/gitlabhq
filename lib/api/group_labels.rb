module API
  class GroupLabels < Grape::API
    include PaginationParams

    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Get all labels of the group' do
        success Entities::Label
      end
      params do
        use :pagination
      end
      get ':id/labels' do
        group_labels = available_labels_for(user_group)

        present paginate(group_labels), with: Entities::Label, current_user: current_user, parent: user_group
      end

      desc 'Create a new label' do
        success Entities::Label
      end
      params do
        requires :name, type: String, desc: 'The name of the label to be created'
        requires :color, type: String, desc: "The color of the label given in 6-digit hex notation with leading '#' sign (e.g. #FFAABB) or one of the allowed CSS color names"
        optional :description, type: String, desc: 'The description of label to be created'
      end
      post ':id/labels' do
        authorize! :admin_label, user_group

        label = available_labels_for(user_group).find_by(title: params[:name])
        conflict!('Label already exists') if label

        label = ::Labels::CreateService.new(declared_params(include_missing: false)).execute(group: user_group)

        if label.valid?
          present label, with: Entities::Label, current_user: current_user, parent: user_group
        else
          render_validation_error!(label)
        end
      end

      desc 'Delete an existing label' do
        success Entities::Label
      end
      params do
        requires :name, type: String, desc: 'The name of the label to be deleted'
      end
      delete ':id/labels' do
        authorize! :admin_label, user_group

        label = user_group.labels.find_by(title: params[:name])
        not_found!('Label') unless label

        destroy_conditionally!(label)
      end

      desc 'Update an existing label. At least one optional parameter is required.' do
        success Entities::Label
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

        label = user_group.labels.find_by(title: params[:name])
        not_found!('Label not found') unless label

        label_params = declared_params(include_missing: false)
        # Rename new name to the actual label attribute name
        label_params[:name] = label_params.delete(:new_name) if label_params.key?(:new_name)

        label = ::Labels::UpdateService.new(label_params).execute(label)
        render_validation_error!(label) unless label.valid?

        present label, with: Entities::Label, current_user: current_user, parent: user_group
      end
    end
  end
end
