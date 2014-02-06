module API
  # Projects API
  class Files < Grape::API
    before { authenticate! }
    before { authorize! :push_code, user_project }

    resource :projects do
      # Create new file in repository
      #
      # Parameters:
      #   file_path (optional) - The path to new file. Ex. lib/class.rb
      #   branch_name (required) - The name of branch
      #   content (required) - File content
      #   commit_message (required) - Commit message
      #
      # Example Request:
      #   POST /projects/:id/repository/files
      #
      post ":id/repository/files" do
        required_attributes! [:file_path, :branch_name, :content, :commit_message]
        attrs = attributes_for_keys [:file_path, :branch_name, :content, :commit_message, :encoding]
        branch_name = attrs.delete(:branch_name)
        file_path = attrs.delete(:file_path)
        result = ::Files::CreateService.new(user_project, current_user, attrs, branch_name, file_path).execute

        if result[:status] == :success
          status(201)

          {
            file_path: file_path,
            branch_name: branch_name
          }
        else
          render_api_error!(result[:error], 400)
        end
      end

      # Update existing file in repository
      #
      # Parameters:
      #   file_path (optional) - The path to file. Ex. lib/class.rb
      #   branch_name (required) - The name of branch
      #   content (required) - File content
      #   commit_message (required) - Commit message
      #
      # Example Request:
      #   PUT /projects/:id/repository/files
      #
      put ":id/repository/files" do
        required_attributes! [:file_path, :branch_name, :content, :commit_message]
        attrs = attributes_for_keys [:file_path, :branch_name, :content, :commit_message, :encoding]
        branch_name = attrs.delete(:branch_name)
        file_path = attrs.delete(:file_path)
        result = ::Files::UpdateService.new(user_project, current_user, attrs, branch_name, file_path).execute

        if result[:status] == :success
          status(200)

          {
            file_path: file_path,
            branch_name: branch_name
          }
        else
          render_api_error!(result[:error], 400)
        end
      end

      # Delete existing file in repository
      #
      # Parameters:
      #   file_path (optional) - The path to file. Ex. lib/class.rb
      #   branch_name (required) - The name of branch
      #   content (required) - File content
      #   commit_message (required) - Commit message
      #
      # Example Request:
      #   DELETE /projects/:id/repository/files
      #
      delete ":id/repository/files" do
        required_attributes! [:file_path, :branch_name, :commit_message]
        attrs = attributes_for_keys [:file_path, :branch_name, :commit_message]
        branch_name = attrs.delete(:branch_name)
        file_path = attrs.delete(:file_path)
        result = ::Files::DeleteService.new(user_project, current_user, attrs, branch_name, file_path).execute

        if result[:status] == :success
          status(200)

          {
            file_path: file_path,
            branch_name: branch_name
          }
        else
          render_api_error!(result[:error], 400)
        end
      end
    end
  end
end
