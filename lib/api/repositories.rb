require 'mime/types'

module API
  class Repositories < Grape::API
    include PaginationParams

    before { authorize! :download_code, user_project }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      helpers do
        def handle_project_member_errors(errors)
          if errors[:project_access].any?
            error!(errors[:project_access], 422)
          end

          not_found!
        end

        def assign_blob_vars!
          authorize! :download_code, user_project

          @repo = user_project.repository

          begin
            @blob = Gitlab::Git::Blob.raw(@repo, params[:sha])
            @blob.load_all_data!(@repo)
          rescue
            not_found! 'Blob'
          end

          not_found! 'Blob' unless @blob
        end
      end

      desc 'Get a project repository tree' do
        success Entities::TreeObject
      end
      params do
        optional :ref, type: String, desc: 'The name of a repository branch or tag, if not given the default branch is used'
        optional :path, type: String, desc: 'The path of the tree'
        optional :recursive, type: Boolean, default: false, desc: 'Used to get a recursive tree'
        use :pagination
      end
      get ':id/repository/tree' do
        ref = params[:ref] || user_project.try(:default_branch) || 'master'
        path = params[:path] || nil

        commit = user_project.commit(ref)
        not_found!('Tree') unless commit

        tree = user_project.repository.tree(commit.id, path, recursive: params[:recursive])
        entries = ::Kaminari.paginate_array(tree.sorted_entries)
        present paginate(entries), with: Entities::TreeObject
      end

      desc 'Get raw blob contents from the repository'
      params do
        requires :sha, type: String, desc: 'The commit hash'
      end
      get ':id/repository/blobs/:sha/raw' do
        assign_blob_vars!

        send_git_blob @repo, @blob
      end

      desc 'Get a blob from the repository'
      params do
        requires :sha, type: String, desc: 'The commit hash'
      end
      get ':id/repository/blobs/:sha' do
        assign_blob_vars!

        {
          size: @blob.size,
          encoding: "base64",
          content: Base64.strict_encode64(@blob.data),
          sha: @blob.id
        }
      end

      desc 'Get an archive of the repository'
      params do
        optional :sha, type: String, desc: 'The commit sha of the archive to be downloaded'
        optional :format, type: String, desc: 'The archive format'
      end
      get ':id/repository/archive', requirements: { format: Gitlab::PathRegex.archive_formats_regex } do
        begin
          send_git_archive user_project.repository, ref: params[:sha], format: params[:format], append_sha: true
        rescue
          not_found!('File')
        end
      end

      desc 'Compare two branches, tags, or commits' do
        success Entities::Compare
      end
      params do
        requires :from, type: String, desc: 'The commit, branch name, or tag name to start comparison'
        requires :to, type: String, desc: 'The commit, branch name, or tag name to stop comparison'
      end
      get ':id/repository/compare' do
        compare = Gitlab::Git::Compare.new(user_project.repository.raw_repository, params[:from], params[:to])
        present compare, with: Entities::Compare
      end

      desc 'Get repository contributors' do
        success Entities::Contributor
      end
      params do
        use :pagination
        optional :order_by, type: String, values: %w[email name commits], default: nil, desc: 'Return contributors ordered by `name` or `email` or `commits`'
        optional :sort, type: String, values: %w[asc desc], default: nil, desc: 'Sort by asc (ascending) or desc (descending)'
      end
      get ':id/repository/contributors' do
        begin
          contributors = ::Kaminari.paginate_array(user_project.repository.contributors(order_by: params[:order_by], sort: params[:sort]))
          present paginate(contributors), with: Entities::Contributor
        rescue
          not_found!
        end
      end
    end
  end
end
