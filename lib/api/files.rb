module API
  # Projects API
  class Files < Grape::API
    before { authenticate! }
    before { authorize! :push_code, user_project }

    resource :projects do
      # Create new file in repository
      #
      # Parameters:
      #   file_name (required) - The name of new file. Ex. class.rb
      #   file_path (optiona) - The path to new file. Ex. lib/
      #   branch_name (required) - The name of branch
      #   content (required) - File content
      #   commit_message (required) - Commit message
      #
      # Example Request:
      #   POST /projects/:id/repository/files
      post ":id/repository/files" do
        required_attributes! [:file_name, :branch_name, :content]
        attrs = attributes_for_keys [:file_name, :file_path, :branch_name, :content]
        branch_name = attrs.delete(:branch_name)
        file_path = attrs.delete(:file_path)
        result = ::Files::CreateContext.new(user_project, current_user, attrs, branch_name, file_path).execute

        if result[:status] == :success
          status(201)

          {
            file_name: attrs[:file_name],
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

