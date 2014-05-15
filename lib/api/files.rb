module API
  # Projects API
  class Files < Grape::API
    before { authenticate! }
    before { authorize! :push_code, user_project }

    resource :projects do
      # Get file from repository
      # File content is Base64 encoded
      #
      # Parameters:
      #   file_path (required) - The path to the file. Ex. lib/class.rb
      #   ref (required) - The name of branch, tag or commit
      #
      # Example Request:
      #   GET /projects/:id/repository/files
      #
      # Example response:
      # {
      #   "file_name": "key.rb",
      #   "file_path": "app/models/key.rb",
      #   "size": 1476,
      #   "encoding": "base64",
      #   "content": "IyA9PSBTY2hlbWEgSW5mb3...",
      #   "ref": "master",
      #   "blob_id": "79f7bbd25901e8334750839545a9bd021f0e4c83",
      #   "commit_id": "d5a3ff139356ce33e37e73add446f16869741b50"
      # }
      #
      get ":id/repository/files" do
        required_attributes! [:file_path, :ref]
        attrs = attributes_for_keys [:file_path, :ref]
        ref = attrs.delete(:ref)
        file_path = attrs.delete(:file_path)

        commit = user_project.repository.commit(ref)
        not_found! "Commit" unless commit

        blob = user_project.repository.blob_at(commit.sha, file_path)

        if blob
          status(200)

          {
            file_name: blob.name,
            file_path: blob.path,
            size: blob.size,
            encoding: "base64",
            content: Base64.encode64(blob.data),
            ref: ref,
            blob_id: blob.id,
            commit_id: commit.id,
          }
        else
          render_api_error!('File not found', 404)
        end
      end

      # Create new file in repository
      #
      # Parameters:
      #   file_path (required) - The path to new file. Ex. lib/class.rb
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
