# frozen_string_literal: true

module API
  class Files < ::API::Base
    include APIGuard

    FILE_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(file_path: API::NO_SLASH_URL_PART_REGEX)

    # Prevents returning plain/text responses for files with .txt extension
    after_validation { content_type "application/json" }

    feature_category :source_code_management

    helpers ::API::Helpers::HeadersHelpers

    helpers do
      def commit_params(attrs)
        {
          file_path: attrs[:file_path],
          start_branch: attrs[:start_branch] || attrs[:branch],
          branch_name: attrs[:branch],
          commit_message: attrs[:commit_message],
          file_content: attrs[:content],
          file_content_encoding: attrs[:encoding],
          author_email: attrs[:author_email],
          author_name: attrs[:author_name],
          last_commit_sha: attrs[:last_commit_id]
        }
      end

      def assign_file_vars!
        authorize! :download_code, user_project

        @commit = user_project.commit(params[:ref])
        not_found!('Commit') unless @commit

        @repo = user_project.repository
        @blob = @repo.blob_at(@commit.sha, params[:file_path])

        not_found!('File') unless @blob
        @blob.load_all_data!
      end

      def commit_response(attrs)
        {
          file_path: attrs[:file_path],
          branch: attrs[:branch]
        }
      end

      def blob_data
        {
          file_name: @blob.name,
          file_path: @blob.path,
          size: @blob.size,
          encoding: "base64",
          content_sha256: Digest::SHA256.hexdigest(@blob.data),
          ref: params[:ref],
          blob_id: @blob.id,
          commit_id: @commit.id,
          last_commit_id: @repo.last_commit_id_for_path(@commit.sha, params[:file_path], literal_pathspec: true)
        }
      end

      params :simple_file_params do
        requires :file_path, type: String, file_path: true, desc: 'The url encoded path to the file. Ex. lib%2Fclass%2Erb'
        requires :branch, type: String, desc: 'Name of the branch to commit into. To create a new branch, also provide `start_branch`.', allow_blank: false
        requires :commit_message, type: String, allow_blank: false, desc: 'Commit message'
        optional :start_branch, type: String, desc: 'Name of the branch to start the new commit from'
        optional :author_email, type: String, desc: 'The email of the author'
        optional :author_name, type: String, desc: 'The name of the author'
      end

      params :extended_file_params do
        use :simple_file_params
        requires :content, type: String, desc: 'File content'
        optional :encoding, type: String, values: %w[base64], desc: 'File encoding'
        optional :last_commit_id, type: String, desc: 'Last known commit id for this file'
      end
    end

    params do
      requires :id, type: String, desc: 'The project ID'
    end
    resource :projects, requirements: FILE_ENDPOINT_REQUIREMENTS do
      allow_access_with_scope :read_repository, if: -> (request) { request.get? || request.head? }

      desc 'Get blame file metadata from repository'
      params do
        requires :file_path, type: String, file_path: true, desc: 'The url encoded path to the file. Ex. lib%2Fclass%2Erb'
        requires :ref, type: String, desc: 'The name of branch, tag or commit', allow_blank: false
      end
      head ":id/repository/files/:file_path/blame", requirements: FILE_ENDPOINT_REQUIREMENTS do
        assign_file_vars!

        set_http_headers(blob_data)
      end

      desc 'Get blame file from the repository'
      params do
        requires :file_path, type: String, file_path: true, desc: 'The url encoded path to the file. Ex. lib%2Fclass%2Erb'
        requires :ref, type: String, desc: 'The name of branch, tag or commit', allow_blank: false
      end
      get ":id/repository/files/:file_path/blame", requirements: FILE_ENDPOINT_REQUIREMENTS do
        assign_file_vars!

        set_http_headers(blob_data)

        blame_ranges = Gitlab::Blame.new(@blob, @commit).groups(highlight: false)
        present blame_ranges, with: Entities::BlameRange
      end

      desc 'Get raw file metadata from repository'
      params do
        requires :file_path, type: String, file_path: true, desc: 'The url encoded path to the file. Ex. lib%2Fclass%2Erb'
        optional :ref, type: String, desc: 'The name of branch, tag or commit', allow_blank: false
      end
      head ":id/repository/files/:file_path/raw", requirements: FILE_ENDPOINT_REQUIREMENTS do
        assign_file_vars!

        set_http_headers(blob_data)
      end

      desc 'Get raw file contents from the repository'
      params do
        requires :file_path, type: String, file_path: true, desc: 'The url encoded path to the file. Ex. lib%2Fclass%2Erb'
        optional :ref, type: String, desc: 'The name of branch, tag or commit', allow_blank: false
      end
      get ":id/repository/files/:file_path/raw", requirements: FILE_ENDPOINT_REQUIREMENTS do
        assign_file_vars!

        no_cache_headers
        set_http_headers(blob_data)

        send_git_blob @repo, @blob
      end

      desc 'Get file metadata from repository'
      params do
        requires :file_path, type: String, file_path: true, desc: 'The url encoded path to the file. Ex. lib%2Fclass%2Erb'
        requires :ref, type: String, desc: 'The name of branch, tag or commit', allow_blank: false
      end
      head ":id/repository/files/:file_path", requirements: FILE_ENDPOINT_REQUIREMENTS do
        assign_file_vars!

        set_http_headers(blob_data)
      end

      desc 'Get a file from the repository'
      params do
        requires :file_path, type: String, file_path: true, desc: 'The url encoded path to the file. Ex. lib%2Fclass%2Erb'
        requires :ref, type: String, desc: 'The name of branch, tag or commit', allow_blank: false
      end
      get ":id/repository/files/:file_path", requirements: FILE_ENDPOINT_REQUIREMENTS do
        assign_file_vars!

        data = blob_data

        set_http_headers(data)

        data.merge(content: Base64.strict_encode64(@blob.data))
      end

      desc 'Create new file in repository'
      params do
        use :extended_file_params
      end
      post ":id/repository/files/:file_path", requirements: FILE_ENDPOINT_REQUIREMENTS do
        authorize! :push_code, user_project

        file_params = declared_params(include_missing: false)
        result = ::Files::CreateService.new(user_project, current_user, commit_params(file_params)).execute

        if result[:status] == :success
          status(201)
          commit_response(file_params)
        else
          render_api_error!(result[:message], 400)
        end
      end

      desc 'Update existing file in repository'
      params do
        use :extended_file_params
      end
      put ":id/repository/files/:file_path", requirements: FILE_ENDPOINT_REQUIREMENTS do
        authorize! :push_code, user_project

        file_params = declared_params(include_missing: false)

        begin
          result = ::Files::UpdateService.new(user_project, current_user, commit_params(file_params)).execute
        rescue ::Files::UpdateService::FileChangedError => e
          render_api_error!(e.message, 400)
        end

        if result[:status] == :success
          status(200)
          commit_response(file_params)
        else
          http_status = result[:http_status] || 400
          render_api_error!(result[:message], http_status)
        end
      end

      desc 'Delete an existing file in repository'
      params do
        use :simple_file_params
      end
      delete ":id/repository/files/:file_path", requirements: FILE_ENDPOINT_REQUIREMENTS do
        authorize! :push_code, user_project

        file_params = declared_params(include_missing: false)
        result = ::Files::DeleteService.new(user_project, current_user, commit_params(file_params)).execute

        if result[:status] != :success
          render_api_error!(result[:message], 400)
        end
      end
    end
  end
end
