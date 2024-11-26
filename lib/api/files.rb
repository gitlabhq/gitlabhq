# frozen_string_literal: true

module API
  class Files < ::API::Base
    include APIGuard

    FILE_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(file_path: API::NO_SLASH_URL_PART_REGEX)

    # Prevents returning plain/text responses for files with .txt extension
    after_validation { content_type "application/json" }

    feature_category :source_code_management

    allow_access_with_scope :read_repository, if: ->(request) { request.get? || request.head? }

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
          last_commit_sha: attrs[:last_commit_id],
          execute_filemode: attrs[:execute_filemode]
        }
      end

      def assign_file_vars!
        authorize_read_code!

        @commit = user_project.commit(params[:ref])
        not_found!('Commit') unless @commit

        @repo = user_project.repository
        @blob = @repo.blob_at(@commit.sha, params[:file_path], limit: Gitlab::Git::Blob::LFS_POINTER_MAX_SIZE)

        not_found!('File') unless @blob
      end

      def commit_response(attrs)
        {
          file_path: attrs[:file_path],
          branch: attrs[:branch]
        }
      end

      def content_sha
        cache_client.fetch(
          "blob_content_sha256:#{user_project.full_path}:#{@blob.id}",
          nil,
          {
            cache_identifier: 'API::Files#content_sha',
            backing_resource: :gitaly
          }
        ) do
          @blob.load_all_data!

          Digest::SHA256.hexdigest(@blob.data)
        end
      end

      def cache_client
        @cache_client ||= Gitlab::Cache::Client.new(
          Gitlab::Cache::Metrics.new(Gitlab::Cache::Metadata.new(feature_category: :source_code_management))
        )
      end

      def fetch_blame_range(blame_params)
        return if blame_params[:range].blank?

        range = Range.new(blame_params[:range][:start], blame_params[:range][:end])

        render_api_error!('range[start] must be less than or equal to range[end]', 400) if range.begin > range.end

        range
      end

      def blob_data
        {
          file_name: @blob.name,
          file_path: @blob.path,
          size: @blob.size,
          encoding: "base64",
          content_sha256: content_sha,
          ref: params[:ref],
          blob_id: @blob.id,
          commit_id: @commit.id,
          last_commit_id: @repo.last_commit_id_for_path(@commit.sha, params[:file_path], literal_pathspec: true),
          execute_filemode: @blob.executable?
        }
      end

      params :simple_file_params do
        requires :file_path, type: String, file_path: true,
          desc: 'The url encoded path to the file.', documentation: { example: 'lib%2Fclass%2Erb' }
        requires :branch, type: String,
          desc: 'Name of the branch to commit into. To create a new branch, also provide `start_branch`.', allow_blank: false,
          documentation: { example: 'main' }
        requires :commit_message, type: String,
          allow_blank: false, desc: 'Commit message', documentation: { example: 'Initial commit' }
        optional :start_branch, type: String,
          desc: 'Name of the branch to start the new commit from', documentation: { example: 'main' }
        optional :author_email, type: String,
          desc: 'The email of the author', documentation: { example: 'johndoe@example.com' }
        optional :author_name, type: String,
          desc: 'The name of the author', documentation: { example: 'John Doe' }
      end

      params :extended_file_params do
        use :simple_file_params
        requires :content, type: String, desc: 'File content', documentation: { example: 'file content' }
        optional :encoding, type: String, values: %w[base64 text], default: 'text', desc: 'File encoding'
        optional :last_commit_id, type: String,
          desc: 'Last known commit id for this file',
          documentation: { example: '2695effb5807a22ff3d138d593fd856244e155e7' }
        optional :execute_filemode, type: Boolean, desc: 'Enable / Disable the executable flag on the file path'
      end
    end

    params do
      requires :id, type: String, desc: 'The project ID', documentation: { example: 'gitlab-org/gitlab' }
    end
    resource :projects, requirements: FILE_ENDPOINT_REQUIREMENTS do
      desc 'Get blame file metadata from repository'
      params do
        requires :file_path, type: String, file_path: true,
          desc: 'The url encoded path to the file.', documentation: { example: 'lib%2Fclass%2Erb' }
        requires :ref, type: String,
          desc: 'The name of branch, tag or commit', allow_blank: false, documentation: { example: 'main' }
      end
      head ":id/repository/files/:file_path/blame", requirements: FILE_ENDPOINT_REQUIREMENTS do
        assign_file_vars!

        set_http_headers(blob_data)
      end

      desc 'Get blame file from the repository'
      params do
        requires :file_path, type: String, file_path: true,
          desc: 'The url encoded path to the file.', documentation: { example: 'lib%2Fclass%2Erb' }
        requires :ref, type: String,
          desc: 'The name of branch, tag or commit', allow_blank: false, documentation: { example: 'main' }
        optional :range, type: Hash do
          requires :start, type: Integer,
            desc: 'The first line of the range to blame', allow_blank: false, values: ->(v) { v > 0 }
          requires :end, type: Integer,
            desc: 'The last line of the range to blame', allow_blank: false, values: ->(v) { v > 0 }
        end
      end
      get ":id/repository/files/:file_path/blame", requirements: FILE_ENDPOINT_REQUIREMENTS do
        blame_params = declared_params(include_missing: false)

        assign_file_vars!

        set_http_headers(blob_data)

        blame_ranges = Gitlab::Blame.new(@blob, @commit, range: fetch_blame_range(blame_params)).groups(highlight: false)
        present blame_ranges, with: Entities::BlameRange
      end

      desc 'Get raw file contents from the repository' do
        success File
      end
      params do
        requires :file_path, type: String, file_path: true,
          desc: 'The url encoded path to the file.', documentation: { example: 'lib%2Fclass%2Erb' }
        optional :ref, type: String,
          desc: 'The name of branch, tag or commit', allow_blank: false, documentation: { example: 'main' }
        optional :lfs, type: Boolean,
          desc: 'Retrieve binary data for a file that is an lfs pointer',
          default: false
      end
      get ":id/repository/files/:file_path/raw", requirements: FILE_ENDPOINT_REQUIREMENTS, urgency: :low do
        assign_file_vars!

        if params[:lfs] && @blob.stored_externally?
          lfs_object = LfsObject.find_by_oid(@blob.lfs_oid)
          not_found! unless lfs_object&.project_allowed_access?(@project)

          present_carrierwave_file!(lfs_object.file)
        else
          no_cache_headers
          set_http_headers(blob_data)

          send_git_blob @repo, @blob
        end
      end

      desc 'Get file metadata from repository'
      params do
        requires :file_path, type: String, file_path: true,
          desc: 'The url encoded path to the file.', documentation: { example: 'lib%2Fclass%2Erb' }
        requires :ref, type: String,
          desc: 'The name of branch, tag or commit', allow_blank: false, documentation: { example: 'main' }
      end
      head ":id/repository/files/:file_path", requirements: FILE_ENDPOINT_REQUIREMENTS, urgency: :low do
        assign_file_vars!

        set_http_headers(blob_data)
      end

      desc 'Get a file from the repository'
      params do
        requires :file_path, type: String, file_path: true,
          desc: 'The url encoded path to the file.', documentation: { example: 'lib%2Fclass%2Erb' }
        requires :ref, type: String,
          desc: 'The name of branch, tag or commit', allow_blank: false, documentation: { example: 'main' }
      end
      get ":id/repository/files/:file_path", requirements: FILE_ENDPOINT_REQUIREMENTS do
        assign_file_vars!

        @blob.load_all_data!

        data = blob_data

        set_http_headers(data)

        data.merge(content: Base64.strict_encode64(@blob.data))
      end

      desc 'Create new file in repository'
      params do
        use :extended_file_params
      end
      post ":id/repository/files/:file_path", requirements: FILE_ENDPOINT_REQUIREMENTS, urgency: :low do
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
      put ":id/repository/files/:file_path", requirements: FILE_ENDPOINT_REQUIREMENTS, urgency: :low do
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
