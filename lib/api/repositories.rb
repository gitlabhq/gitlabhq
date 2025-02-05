# frozen_string_literal: true

require 'mime/types'

module API
  class Repositories < ::API::Base
    include PaginationParams
    include Helpers::Unidiff

    content_type :txt, 'text/plain'

    helpers ::API::Helpers::HeadersHelpers

    helpers do
      params :release_params do
        requires :version,
          type: String,
          regexp: Gitlab::Regex.unbounded_semver_regex,
          desc: 'The version of the release, using the semantic versioning format',
          documentation: { example: '1.0.0' }

        optional :from,
          type: String,
          desc: 'The first commit in the range of commits to use for the changelog',
          documentation: { example: 'ed899a2f4b50b4370feeea94676502b42383c746' }

        optional :to,
          type: String,
          desc: 'The last commit in the range of commits to use for the changelog',
          documentation: { example: '6104942438c14ec7bd21c6cd5bd995272b3faff6' }

        optional :date,
          type: DateTime,
          desc: 'The date and time of the release',
          documentation: { type: 'dateTime', example: '2021-09-20T11:50:22.001+00:00' }

        optional :trailer,
          type: String,
          desc: 'The Git trailer to use for determining if commits are to be included in the changelog',
          default: ::Repositories::ChangelogService::DEFAULT_TRAILER,
          documentation: { example: 'Changelog' }
      end
    end

    before { authorize_read_code! }

    feature_category :source_code_management

    params do
      requires :id, types: [String, Integer],
        desc: 'The ID or URL-encoded path of the project',
        documentation: { example: 1 }
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
          authorize_read_code!

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
        optional :ref, type: String,
          desc: 'The name of a repository branch or tag, if not given the default branch is used',
          documentation: { example: 'main' }
        optional :path, type: String, desc: 'The path of the tree', documentation: { example: 'files/html' }
        optional :recursive, type: Boolean, default: false, desc: 'Used to get a recursive tree'

        use :pagination
        optional :pagination, type: String, values: %w[legacy keyset none], default: 'legacy', desc: 'Specify the pagination method ("none" is only valid if "recursive" is true)'

        given pagination: ->(value) { value == 'keyset' } do
          optional :page_token, type: String,
            desc: 'Record from which to start the keyset pagination',
            documentation: { example: 'a1e8f8d745cc87e3a9248358d9352bb7f9a0aeba' }
        end

        given pagination: ->(value) { value == 'none' } do
          given recursive: ->(value) { value == false } do
            validates([:pagination], except_values: { value: 'none', message: 'cannot be "none" unless "recursive" is true' })
          end
        end
      end
      get ':id/repository/tree', urgency: :low do
        tree_finder = ::Repositories::TreeFinder.new(user_project, declared_params(include_missing: false).merge(rescue_not_found: false))

        not_found!("Tree") unless tree_finder.commit_exists?

        tree = Gitlab::Pagination::GitalyKeysetPager.new(self, user_project).paginate(tree_finder)

        present tree, with: Entities::TreeObject

      rescue Gitlab::Git::Index::IndexError => e
        not_found!(e.message)
      end

      desc 'Get raw blob contents from the repository'
      params do
        requires :sha, type: String,
          desc: 'The commit hash', documentation: { example: '7d70e02340bac451f281cecf0a980907974bd8be' }
      end
      get ':id/repository/blobs/:sha/raw' do
        # Load metadata enough to ask Workhorse to load the whole blob
        assign_blob_vars!(limit: 0)

        no_cache_headers

        send_git_blob @repo, @blob
      end

      desc 'Get a blob from the repository'
      params do
        requires :sha, type: String,
          desc: 'The commit hash', documentation: { example: '7d70e02340bac451f281cecf0a980907974bd8be' }
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
        optional :sha, type: String,
          desc: 'The commit sha of the archive to be downloaded',
          documentation: { example: '7d70e02340bac451f281cecf0a980907974bd8be' }
        optional :format, type: String, desc: 'The archive format', documentation: { example: 'tar.gz' }
        optional :path, type: String,
          desc: 'Subfolder of the repository to be downloaded', documentation: { example: 'files/archives' }
        optional :include_lfs_blobs, type: Boolean, default: true,
          desc: 'Used to exclude LFS objects from archive'
      end
      get ':id/repository/archive', requirements: { format: Gitlab::PathRegex.archive_formats_regex } do
        check_archive_rate_limit!(current_user, user_project) do
          render_api_error!({ error: _('This archive has been requested too many times. Try again later.') }, 429)
        end

        not_acceptable! if Gitlab::HotlinkingDetector.intercept_hotlinking?(request)

        send_git_archive user_project.repository, ref: params[:sha], format: params[:format], append_sha: true, path: params[:path], include_lfs_blobs: params[:include_lfs_blobs]
      rescue StandardError
        not_found!('File')
      end

      desc 'Compare two branches, tags, or commits' do
        success Entities::Compare
      end
      params do
        requires :from, type: String,
          desc: 'The commit, branch name, or tag name to start comparison',
          documentation: { example: 'main' }
        requires :to, type: String,
          desc: 'The commit, branch name, or tag name to stop comparison',
          documentation: { example: 'feature' }
        optional :from_project_id, type: Integer, desc: 'The project to compare from', documentation: { example: 1 }
        optional :straight, type: Boolean, desc: 'Comparison method, `true` for direct comparison between `from` and `to` (`from`..`to`), `false` to compare using merge base (`from`...`to`)', default: false
        use :with_unidiff
      end
      get ':id/repository/compare', urgency: :low do
        target_project = fetch_target_project(current_user, user_project, params)

        if target_project.blank?
          render_api_error!("Target project id:#{params[:from_project_id]} is not a fork of project id:#{params[:id]}", 400)
        end

        unless can?(current_user, :read_code, target_project)
          forbidden!("You don't have access to this fork's parent project")
        end

        cache_key = compare_cache_key(current_user, user_project, target_project, declared_params)

        cache_action(cache_key, expires_in: 1.minute) do
          compare = CompareService.new(user_project, params[:to]).execute(target_project, params[:from], straight: params[:straight])

          if compare
            present compare, with: Entities::Compare, current_user: current_user, enable_unidiff: declared_params[:unidiff]
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
        optional :ref, type: String,
          desc: 'The name of a repository branch or tag, if not given the default branch is used',
          documentation: { example: 'main' }
        optional :order_by, type: String, values: %w[email name commits], default: 'commits', desc: 'Return contributors ordered by `name` or `email` or `commits`'
        optional :sort, type: String, values: %w[asc desc], default: 'asc', desc: 'Sort by asc (ascending) or desc (descending)'
      end
      get ':id/repository/contributors' do
        contributors = ::Kaminari.paginate_array(user_project.repository.contributors(ref: params[:ref], order_by: params[:order_by], sort: params[:sort]))
        present paginate(contributors), with: Entities::Contributor
      rescue StandardError
        not_found!
      end

      desc 'Get the common ancestor between commits' do
        success Entities::Commit
      end
      params do
        requires :refs, type: Array[String],
          coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
          desc: 'The refs to find the common ancestor of, multiple refs can be passed',
          documentation: { example: 'main' }
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
        success Entities::Changelog
      end
      params do
        use :release_params

        optional :config_file,
          type: String,
          documentation: { example: '.gitlab/changelog_config.yml' },
          desc: "The file path to the configuration file as stored in the project's Git repository. Defaults to '.gitlab/changelog_config.yml'"
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: :read_releases
      get ':id/repository/changelog' do
        check_rate_limit!(:project_repositories_changelog, scope: [current_user, user_project]) do
          render_api_error!({ error: 'This changelog has been requested too many times. Try again later.' }, 429)
        end

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
        success code: 200
      end
      params do
        use :release_params

        optional :branch,
          type: String,
          desc: 'The branch to commit the changelog changes to',
          documentation: { example: 'main' }

        optional :config_file,
          type: String,
          documentation: { example: '.gitlab/changelog_config.yml' },
          desc: "The file path to the configuration file as stored in the project's Git repository. Defaults to '.gitlab/changelog_config.yml'"

        optional :file,
          type: String,
          desc: 'The file to commit the changelog changes to',
          default: ::Repositories::ChangelogService::DEFAULT_FILE,
          documentation: { example: 'CHANGELOG.md' }

        optional :message,
          type: String,
          desc: 'The commit message to use when committing the changelog',
          documentation: { example: 'Initial commit' }
      end
      post ':id/repository/changelog' do
        check_rate_limit!(:project_repositories_changelog, scope: [current_user, user_project]) do
          render_api_error!({ error: 'This changelog has been requested too many times. Try again later.' }, 429)
        end

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
