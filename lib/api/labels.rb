module API
  # Labels API
  class Labels < Grape::API
    before { authenticate! }

    resource :projects do
      # Get all labels of the project
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id/labels
      get ':id/labels' do
        present user_project.labels, with: Entities::Label
      end

      # Creates a new label
      #
      # Parameters:
      #   id    (required) - The ID of a project
      #   name  (required) - The name of the label to be deleted
      #   color (required) - Color of the label given in 6-digit hex
      #                      notation with leading '#' sign (e.g. #FFAABB)
      # Example Request:
      #   POST /projects/:id/labels
      post ':id/labels' do
        required_attributes! [:name, :color]

        attrs = attributes_for_keys [:name, :color]
        label = user_project.find_label(attrs[:name])

        if label
          return render_api_error!('Label already exists', 409)
        end

        label = user_project.labels.create(attrs)

        if label.valid?
          present label, with: Entities::Label
        else
          render_api_error!(label.errors.full_messages.join(', '), 405)
        end
      end

      # Deletes an existing label
      #
      # Parameters:
      #   id    (required) - The ID of a project
      #   name  (required) - The name of the label to be deleted
      #
      # Example Request:
      #   DELETE /projects/:id/labels
      delete ':id/labels' do
        required_attributes! [:name]

        label = user_project.find_label(params[:name])
        if !label
          return render_api_error!('Label not found', 404)
        end

        label.destroy
      end
    end
  end
end
