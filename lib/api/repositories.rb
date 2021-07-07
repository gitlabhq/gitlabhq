# frozen_string_literal: true

require 'mime/types'

module API
  class Repositories < ::API::Base
    include PaginationParams

    content_type :txt, 'text/plain'

    helpers ::API::Helpers::HeadersHelpers

    before { authorize! :download_code, user_project }

    feature_category :source_code_management

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      helpers do
        include ::Gitlab::RateLimitHelpers

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
          rescue StandardError
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

        no_cache_headers

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
        if archive_rate_limit_reached?(current_user, user_project)
          render_api_error!({ error: ::Gitlab::RateLimitHelpers::ARCHIVE_RATE_LIMIT_REACHED_MESSAGE }, 429)
        end

        not_acceptable! if Gitlab::HotlinkingDetector.intercept_hotlinking?(request)

        send_git_archive user_project.repository, ref: params[:sha], format: params[:format], append_sha: true
      rescue StandardError
        not_found!('File')
      end

      desc 'Compare two branches, tags, or commits' do
        success Entities::Compare
      end
      params do
        requires :from, type: String, desc: 'The commit, branch name, or tag name to start comparison'
        requires :to, type: String, desc: 'The commit, branch name, or tag name to stop comparison'
        optional :from_project_id, type: String, desc: 'The project to compare from'
        optional :straight, type: Boolean, desc: 'Comparison method, `true` for direct comparison between `from` and `to` (`from`..`to`), `false` to compare using merge base (`from`...`to`)', default: false
      end
      get ':id/repository/compare' do
        ff_enabled = Feature.enabled?(:api_caching_rate_limit_repository_compare, user_project, default_enabled: :yaml)

        cache_action_if(ff_enabled, [user_project, :repository_compare, current_user, declared_params], expires_in: 30.seconds) do
          if params[:from_project_id].present?
            target_project = MergeRequestTargetProjectFinder
              .new(current_user: current_user, source_project: user_project, project_feature: :repository)
              .execute(include_routes: true).find_by_id(params[:from_project_id])

            if target_project.blank?
              render_api_error!("Target project id:#{params[:from_project_id]} is not a fork of project id:#{params[:id]}", 400)
            end
          else
            target_project = user_project
          end

          compare = CompareService.new(user_project, params[:to]).execute(target_project, params[:from], straight: params[:straight])

          if compare
            if Feature.enabled?(:api_caching_repository_compare, user_project, default_enabled: :yaml)
              present_cached compare, with: Entities::Compare, expires_in: 1.day, cache_context: nil
            else
              present compare, with: Entities::Compare
            end
          else
            not_found!("Ref")
          end
        end
      end

      desc 'Get repository contributors' do
        success Entities::Contributor
      end
      params do
        use :pagination
        optional :order_by, type: String, values: %w[email name commits], default: 'commits', desc: 'Return contributors ordered by `name` or `email` or `commits`'
        optional :sort, type: String, values: %w[asc desc], default: 'asc', desc: 'Sort by asc (ascending) or desc (descending)'
      end
      get ':id/repository/contributors' do
        contributors = ::Kaminari.paginate_array(user_project.repository.contributors(order_by: params[:order_by], sort: params[:sort]))
        present paginate(contributors), with: Entities::Contributor
      rescue StandardError
        not_found!
      end

      desc 'Get the common ancestor between commits' do
        success Entities::Commit
      end
      params do
        requires :refs, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce
      end
      get ':id/repository/merge_base' do
        refs = params[:refs]

        if refs.size < 2
          render_api_error!('Provide at least 2 refs', 400)
        end

        merge_base = Gitlab::Git::MergeBase.new(user_project.repository, refs)

        if merge_base.unknown_refs.any?
          ref_noun = 'ref'.pluralize(merge_base.unknown_refs.size)
          message = "Could not find #{ref_noun}: #{merge_base.unknown_refs.join(', ')}"
          render_api_error!(message, 400)
        end

        if merge_base.commit
          present merge_base.commit, with: Entities::Commit
        else
          not_found!("Merge Base")
        end
      end

      desc 'Generates a changelog section for a release' do
        detail 'This feature was introduced in GitLab 13.9'
      end
      params do
        requires :version,
          type: String,
          regexp: Gitlab::Regex.unbounded_semver_regex,
          desc: 'The version of the release, using the semantic versioning format'

        optional :from,
          type: String,
          desc: 'The first commit in the range of commits to use for the changelog'

        optional :to,
          type: String,
          desc: 'The last commit in the range of commits to use for the changelog'

        optional :date,
          type: DateTime,
          desc: 'The date and time of the release'

        optional :branch,
          type: String,
          desc: 'The branch to commit the changelog changes to'

        optional :trailer,
          type: String,
          desc: 'The Git trailer to use for determining if commits are to be included in the changelog',
          default: ::Repositories::ChangelogService::DEFAULT_TRAILER

        optional :file,
          type: String,
          desc: 'The file to commit the changelog changes to',
          default: ::Repositories::ChangelogService::DEFAULT_FILE

        optional :message,
          type: String,
          desc: 'The commit message to use when committing the changelog'
      end
      post ':id/repository/changelog' do
        branch = params[:branch] || user_project.default_branch_or_main
        access = Gitlab::UserAccess.new(current_user, container: user_project)

        unless access.can_push_to_branch?(branch)
          forbidden!("You are not allowed to commit a changelog on this branch")
        end

        service = ::Repositories::ChangelogService.new(
          user_project,
          current_user,
          **declared_params(include_missing: false)
        )

        service.execute
        status(200)
      rescue Gitlab::Changelog::Error => ex
        render_api_error!("Failed to generate the changelog: #{ex.message}", 422)
      end
    end
  end
end
