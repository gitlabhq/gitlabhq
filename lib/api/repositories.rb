# frozen_string_literal: true

require 'mime/types'

module API
  class Repositories < ::API::Base
    include PaginationParams

    content_type :txt, 'text/plain'

    helpers ::API::Helpers::HeadersHelpers

    helpers do
      params :release_params do
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

        optional :trailer,
          type: String,
          desc: 'The Git trailer to use for determining if commits are to be included in the changelog',
          default: ::Repositories::ChangelogService::DEFAULT_TRAILER
      end
    end

    before { authorize! :download_code, user_project }

    feature_category :source_code_management

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      helpers do
        include Gitlab::RepositoryArchiveRateLimiter

        def handle_project_member_errors(errors)
          if errors[:project_access].any?
            error!(errors[:project_access], 422)
          end

          not_found!
        end

        def assign_blob_vars!(limit:)
          authorize! :download_code, user_project

          @repo = user_project.repository

          begin
            @blob = Gitlab::Git::Blob.raw(@repo, params[:sha], limit: limit)
          rescue StandardError
            not_found! 'Blob'
          end

          not_found! 'Blob' unless @blob
        end

        def fetch_target_project(current_user, user_project, params)
          return user_project unless params[:from_project_id].present?

          MergeRequestTargetProjectFinder
            .new(current_user: current_user, source_project: user_project, project_feature: :repository)
            .execute(include_routes: true).find_by_id(params[:from_project_id])
        end

        def compare_cache_key(current_user, user_project, target_project, params)
          [
            user_project,
            target_project,
            current_user,
            :repository_compare,
            target_project.repository.commit(params[:from]),
            user_project.repository.commit(params[:to]),
            params
          ]
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
        optional :pagination, type: String, values: %w(legacy keyset), default: 'legacy', desc: 'Specify the pagination method'

        given pagination: -> (value) { value == 'keyset' } do
          optional :page_token, type: String, desc: 'Record from which to start the keyset pagination'
        end
      end
      get ':id/repository/tree', urgency: :low do
        tree_finder = ::Repositories::TreeFinder.new(user_project, declared_params(include_missing: false))

        not_found!("Tree") unless tree_finder.commit_exists?

        tree = Gitlab::Pagination::GitalyKeysetPager.new(self, user_project).paginate(tree_finder)

        present tree, with: Entities::TreeObject
      end

      desc 'Get raw blob contents from the repository'
      params do
        requires :sha, type: String, desc: 'The commit hash'
      end
      get ':id/repository/blobs/:sha/raw' do
        # Load metadata enough to ask Workhorse to load the whole blob
        assign_blob_vars!(limit: 0)

        no_cache_headers

        send_git_blob @repo, @blob
      end

      desc 'Get a blob from the repository'
      params do
        requires :sha, type: String, desc: 'The commit hash'
      end
      get ':id/repository/blobs/:sha' do
        assign_blob_vars!(limit: -1)

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
        optional :path, type: String, desc: 'Subfolder of the repository to be downloaded'
      end
      get ':id/repository/archive', requirements: { format: Gitlab::PathRegex.archive_formats_regex } do
        check_archive_rate_limit!(current_user, user_project) do
          render_api_error!({ error: _('This archive has been requested too many times. Try again later.') }, 429)
        end

        not_acceptable! if Gitlab::HotlinkingDetector.intercept_hotlinking?(request)

        send_git_archive user_project.repository, ref: params[:sha], format: params[:format], append_sha: true, path: params[:path]
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
      get ':id/repository/compare', urgency: :low do
        target_project = fetch_target_project(current_user, user_project, params)

        if target_project.blank?
          render_api_error!("Target project id:#{params[:from_project_id]} is not a fork of project id:#{params[:id]}", 400)
        end

        cache_key = compare_cache_key(current_user, user_project, target_project, declared_params)

        cache_action(cache_key, expires_in: 1.minute) do
          compare = CompareService.new(user_project, params[:to]).execute(target_project, params[:from], straight: params[:straight])

          if compare
            present compare, with: Entities::Compare
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

      desc 'Generates a changelog section for a release and returns it' do
        detail 'This feature was introduced in GitLab 14.6'
      end
      params do
        use :release_params

        optional :config_file,
          type: String,
          desc: "The file path to the configuration file as stored in the project's Git repository. Defaults to '.gitlab/changelog_config.yml'"
      end
      get ':id/repository/changelog' do
        service = ::Repositories::ChangelogService.new(
          user_project,
          current_user,
          **declared_params(include_missing: false)
        )
        changelog = service.execute(commit_to_changelog: false)

        present changelog, with: Entities::Changelog
      rescue Gitlab::Changelog::Error => ex
        render_api_error!("Failed to generate the changelog: #{ex.message}", 422)
      end

      desc 'Generates a changelog section for a release and commits it in a changelog file' do
        detail 'This feature was introduced in GitLab 13.9'
      end
      params do
        use :release_params

        optional :branch,
          type: String,
          desc: 'The branch to commit the changelog changes to'

        optional :config_file,
          type: String,
          desc: "The file path to the configuration file as stored in the project's Git repository. Defaults to '.gitlab/changelog_config.yml'"

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

        service.execute(commit_to_changelog: true)
        status(200)
      rescue Gitlab::Changelog::Error => ex
        render_api_error!("Failed to generate the changelog: #{ex.message}", 422)
      end
    end
  end
end

API::Repositories.prepend_mod
