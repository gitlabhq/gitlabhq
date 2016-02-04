module API
  # Projects API
  class Files < Grape::API
    before { authenticate! }

    helpers do
      def commit_params(attrs)
        {
          file_path: attrs[:file_path],
          source_branch: attrs[:branch_name],
          target_branch: attrs[:branch_name],
          commit_message: attrs[:commit_message],
          file_content: attrs[:content],
          file_content_encoding: attrs[:encoding]
        }
      end

      def commit_response(attrs)
        {
          file_path: attrs[:file_path],
          branch_name: attrs[:branch_name],
        }
      end
    end

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
      #   "commit_id": "d5a3ff139356ce33e37e73add446f16869741b50",
      #   "last_commit_id": "570e7b2abdd848b95f2f578043fc23bd6f6fd24d",
      # }
      #
      get ":id/repository/files" do
        authorize! :download_code, user_project

        required_attributes! [:file_path, :ref]
        attrs = attributes_for_keys [:file_path, :ref]
        ref = attrs.delete(:ref)
        file_path = attrs.delete(:file_path)

        commit = user_project.commit(ref)
        not_found! 'Commit' unless commit

        repo = user_project.repository
        blob = repo.blob_at(commit.sha, file_path)

        if blob
          blob.load_all_data!(repo)
          status(200)

          {
            file_name: blob.name,
            file_path: blob.path,
            size: blob.size,
            encoding: "base64",
            content: Base64.strict_encode64(blob.data),
            ref: ref,
            blob_id: blob.id,
            commit_id: commit.id,
            last_commit_id: repo.last_commit_for_path(commit.sha, file_path).id
          }
        else
          not_found! 'File'
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
        authorize! :push_code, user_project

        required_attributes! [:file_path, :branch_name, :content, :commit_message]
        attrs = attributes_for_keys [:file_path, :branch_name, :content, :commit_message, :encoding]
        result = ::Files::CreateService.new(user_project, current_user, commit_params(attrs)).execute

        if result[:status] == :success
          status(201)
          commit_response(attrs)
        else
          render_api_error!(result[:message], 400)
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
        authorize! :push_code, user_project

        required_attributes! [:file_path, :branch_name, :content, :commit_message]
        attrs = attributes_for_keys [:file_path, :branch_name, :content, :commit_message, :encoding]
        result = ::Files::UpdateService.new(user_project, current_user, commit_params(attrs)).execute

        if result[:status] == :success
          status(200)
          commit_response(attrs)
        else
          http_status = result[:http_status] || 400
          render_api_error!(result[:message], http_status)
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
        authorize! :push_code, user_project

        required_attributes! [:file_path, :branch_name, :commit_message]
        attrs = attributes_for_keys [:file_path, :branch_name, :commit_message]
        result = ::Files::DeleteService.new(user_project, current_user, commit_params(attrs)).execute

        if result[:status] == :success
          status(200)
          commit_response(attrs)
        else
          render_api_error!(result[:message], 400)
        end
      end
    end
  end
end
