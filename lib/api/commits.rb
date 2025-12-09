# frozen_string_literal: true
require 'mime/types'

module API
  class Commits < ::API::Base
    include ::API::Concerns::AiWorkflowsAccess
    include APIGuard
    include PaginationParams
    include Helpers::Unidiff

    helpers ::API::Helpers::NotesHelpers
    helpers ::API::Helpers::CommitsBodyUploaderHelper

    allow_ai_workflows_access

    feature_category :source_code_management

    before do
      require_repository_enabled!
      authorize_read_code!

      verify_pagination_params!
    end

    rescue_from Oj::ParseError do |e|
      Gitlab::ErrorTracking.track_exception(e)

      message = 'Invalid json'
      render_structured_api_error!({ message: message, error: message }, 400)
    end

    helpers do
      def user_access
        @user_access ||= Gitlab::UserAccess.new(current_user, container: user_project)
      end

      def authorize_push_to_branch!(branch)
        authenticate!

        unless user_access.can_push_to_branch?(branch)
          forbidden!("You are not allowed to push into this branch")
        end
      end

      def web_ide_request?
        return false unless access_token.respond_to?(:application)

        access_token.application.id == WebIde::DefaultOauthApplication.oauth_application_id
      end

      def track_web_ide_commit_events
        return unless web_ide_request?

        Gitlab::InternalEvents.track_event('create_commit_from_web_ide', user: current_user, project: user_project)
        Gitlab::InternalEvents.track_event('g_edit_by_web_ide', user: current_user, project: user_project)

        namespace = user_project.namespace

        Gitlab::Tracking.event(
          'API::Commits',
          :commit,
          project: user_project,
          namespace: namespace,
          user: current_user,
          label: 'counts.web_ide_commits',
          context: [Gitlab::Tracking::ServicePingContext.new(
            data_source: 'redis_hll',
            event: 'create_commit_from_web_ide'
          ).to_context]
        )
      end

      def validate_commits_attrs!(attrs)
        bad_request!('branch is required') if attrs[:branch].blank?
        bad_request!('commit_message is required') if attrs[:commit_message].blank?
        bad_request!('actions is required') if attrs[:actions].blank?

        if attrs.key?(:start_sha) && attrs.key?(:start_branch)
          bad_request!('start_branch, start_sha are mutually exclusive')
        end

        attrs[:actions].each_with_index do |action, index|
          bad_request!("actions[#{index}][action] is required") if action[:action].blank?
          bad_request!("actions[#{index}][file_path] is required") if action[:file_path].blank?

          err = validate_commit_action!(action, index)

          bad_request!(err) if err
        end

        filter_commits_attrs!(attrs)
      end

      def validate_commit_action!(action, index)
        if %w[create update move delete chmod].exclude?(action[:action])
          return "actions[#{index}][action] must be one of: create, update, move, delete, chmod"
        end

        if action.key?(:encoding)
          return "actions[#{index}][encoding] must be text or base64" if %w[text base64].exclude?(action[:encoding])
        else
          action[:encoding] = 'text'
        end

        case action[:action]
        when 'update'
          "actions[#{index}][content] is required for update action" unless action.key?(:content)
        when 'move'
          "actions[#{index}][previous_path] is required for move action" if action[:previous_path].blank?
        when 'chmod'
          if !action.key?(:execute_filemode)
            "actions[#{index}][execute_filemode] is required for chmod action"
          elsif [true, false, "true", "false"].exclude?(action[:execute_filemode])
            "actions[#{index}][execute_filemode] must be a boolean"
          else
            action[:execute_filemode] = ActiveModel::Type::Boolean.new.cast(action[:execute_filemode])
            nil
          end
        end
      end

      def filter_commits_attrs!(attrs)
        attrs.slice!(
          :branch,
          :commit_message,
          :actions,
          :start_branch,
          :start_sha,
          :start_project,
          :author_email,
          :author_name,
          :stats,
          :force
        )

        attrs[:actions].each do |action|
          action.slice!(
            :action,
            :file_path,
            :previous_path,
            :content,
            :encoding,
            :last_commit_id,
            :execute_filemode
          )
        end
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS, urgency: :low do
      desc 'Get a project repository commits' do
        success code: 200, model: Entities::Commit
        tags %w[commits]
        is_array true
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        optional :ref_name,
          type: String,
          desc: 'The name of a repository branch or tag, if not given the default branch is used',
          documentation: { example: 'v1.1.0' }
        optional :since,
          type: DateTime,
          desc: 'Only commits after or on this date will be returned',
          documentation: { example: '2021-09-20T11:50:22.001' }
        optional :until,
          type: DateTime,
          desc: 'Only commits before or on this date will be returned',
          documentation: { example: '2021-09-20T11:50:22.001' }
        optional :path,
          type: String,
          desc: 'The file path',
          documentation: { example: 'README.md' }
        optional :author,
          type: String,
          desc: 'Search commits by commit author',
          documentation: { example: 'John Smith' }
        optional :all, type: Boolean, desc: 'Every commit will be returned'
        optional :with_stats, type: Boolean, desc: 'Stats about each commit will be added to the response'
        optional :first_parent, type: Boolean, desc: 'Only include the first parent of merges'
        optional :order, type: String, desc: 'List commits in order', default: 'default', values: %w[default topo]
        optional :trailers, type: Boolean, desc: 'Parse and include Git trailers for every commit', default: false
        use :pagination
      end
      get ':id/repository/commits', urgency: :low do
        not_found! 'Repository' unless user_project.repository_exists?

        page = params[:page] > 0 ? params[:page] : 1
        per_page = params[:per_page] > 0 ? params[:per_page] : Kaminari.config.default_per_page
        limit = [per_page, Kaminari.config.max_per_page].min
        offset = (page - 1) * limit

        path = params[:path]
        before = params[:until]
        after = params[:since]
        ref = params[:ref_name].presence || user_project.default_branch unless params[:all]
        all = params[:all]
        with_stats = params[:with_stats]
        first_parent = params[:first_parent]
        order = params[:order]
        author = params[:author]

        commits = user_project.repository.commits(ref,
          path: path,
          limit: limit,
          offset: offset,
          before: before,
          after: after,
          all: all,
          first_parent: first_parent,
          order: order,
          author: author,
          trailers: params[:trailers])

        serializer = with_stats ? Entities::CommitWithStats : Entities::Commit

        # This tells kaminari that there is 1 more commit after the one we've
        # loaded, meaning there will be a next page, if the currently loaded set
        # of commits is equal to the requested page size.
        commit_count = offset + commits.size + 1
        paginated_commits = Kaminari.paginate_array(commits, total_count: commit_count)

        present paginate(paginated_commits, exclude_total_headers: true, without_count: true), with: serializer

      rescue ArgumentError
        render_api_error!('ref_name is invalid', 400)
      end

      # POST /:id/repository/commits/authorize'
      desc 'Authorize commits upload' do
        success code: 200
        failure [
          { code: 400, message: 'Bad Request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[commits]
        hidden true
      end
      post ':id/repository/commits/authorize' do
        workhorse_authorize_commits_body_upload!
      end

      desc 'Commit multiple file changes as one commit' do
        success code: 200, model: Entities::CommitDetail
        tags %w[commits]
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        detail 'This feature was introduced in GitLab 8.13'
      end
      params do
        requires :file, type: ::API::Validations::Types::WorkhorseFile, desc: 'The commit content to be created (generated by Multipart middleware)', documentation: { type: 'file' }
      end
      post ':id/repository/commits' do
        require_gitlab_workhorse!

        attrs = file_params_from_body_upload

        authorize_push_to_branch!(attrs[:branch])

        validate_commits_attrs!(attrs)

        if attrs[:start_project]
          start_project = find_project!(attrs[:start_project])

          unless can?(current_user, :read_code, start_project) && user_project.forked_from?(start_project)
            forbidden!("Project is not included in the fork network for #{start_project.full_name}")
          end
        end

        attrs[:branch_name] = attrs.delete(:branch)
        attrs[:start_branch] ||= attrs[:branch_name] unless attrs[:start_sha]
        attrs[:start_project] = start_project if start_project
        attrs[:stats] = ActiveModel::Type::Boolean.new.cast(attrs[:stats]) != false # default: true
        attrs[:force] = ActiveModel::Type::Boolean.new.cast(attrs[:force]) == true # default: false

        result = ::Files::MultiService.new(user_project, current_user, attrs).execute

        if result[:status] == :success
          commit_detail = user_project.repository.commit(result[:result])

          track_web_ide_commit_events

          present commit_detail, with: Entities::CommitDetail, include_stats: attrs[:stats], current_user: current_user
        else
          render_api_error!(result[:message], 400)
        end
      end

      desc 'Get a specific commit of a project' do
        success code: 200, model: Entities::CommitDetail
        tags %w[commits]
        failure [
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :sha, type: String, desc: 'A commit sha, or the name of a branch or tag'
        optional :stats, type: Boolean, default: true, desc: 'Include commit stats'
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: :read_repositories,
        allow_public_access_for_enabled_project_features: :repository
      get ':id/repository/commits/:sha', requirements: API::COMMIT_ENDPOINT_REQUIREMENTS do
        commit = user_project.commit(params[:sha])

        not_found! 'Commit' unless commit

        present commit, with: Entities::CommitDetail, include_stats: params[:stats], current_user: current_user
      end

      desc 'Get the diff for a specific commit of a project' do
        success code: 200, model: Entities::Diff
        tags %w[commits]
        is_array true
        failure [
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :sha, type: String, desc: 'A commit sha, or the name of a branch or tag'
        use :pagination
        use :with_unidiff
      end
      get ':id/repository/commits/:sha/diff', requirements: API::COMMIT_ENDPOINT_REQUIREMENTS, urgency: :low do
        commit = user_project.commit(params[:sha])

        not_found! 'Commit' unless commit

        raw_diffs = ::Kaminari.paginate_array(commit.diffs(expanded: true).diffs.to_a)

        present paginate(raw_diffs), with: Entities::Diff, enable_unidiff: declared_params[:unidiff]
      end

      desc "Get a commit's comments" do
        success code: 200, model: Entities::CommitNote
        tags %w[commits]
        is_array true
        failure [
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        use :pagination
        requires :sha, type: String, desc: 'A commit sha, or the name of a branch or tag'
      end
      get ':id/repository/commits/:sha/comments', requirements: API::COMMIT_ENDPOINT_REQUIREMENTS do
        commit = user_project.commit(params[:sha])

        not_found! 'Commit' unless commit
        notes = commit.notes.with_api_entity_associations.order_created_at_id_asc

        present paginate(notes), with: Entities::CommitNote
      end

      desc 'Get the sequence count of a commit SHA' do
        success code: 200, model: Entities::CommitSequence
        tags %w[commits]
        failure [
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :sha, type: String, desc: 'A commit SHA'
        optional :first_parent, type: Boolean, desc: 'Only include the first parent of merges', default: false
      end
      get ':id/repository/commits/:sha/sequence', requirements: API::COMMIT_ENDPOINT_REQUIREMENTS do
        commit = user_project.commit(params[:sha])

        not_found! 'Commit' unless commit
        count = user_project.repository.count_commits(ref: params[:sha], first_parent: params[:first_parent])
        count_hash = { count: count }

        present count_hash, with: Entities::CommitSequence
      end

      desc 'Cherry pick commit into a branch' do
        detail 'This feature was introduced in GitLab 8.15'
        success code: 200, model: Entities::Commit
        tags %w[commits]
        failure [
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :sha, type: String, desc: 'A commit sha, or the name of a branch or tag to be cherry-picked'
        requires :branch,
          type: String,
          desc: 'The name of the branch',
          allow_blank: false,
          documentation: { example: 'master' }
        optional :dry_run, type: Boolean, default: false, desc: "Does not commit any changes"
        optional :message,
          type: String,
          desc: 'A custom commit message to use for the picked commit',
          documentation: { example: 'Initial commit' }
      end
      post ':id/repository/commits/:sha/cherry_pick', requirements: API::COMMIT_ENDPOINT_REQUIREMENTS do
        authorize_push_to_branch!(params[:branch])

        commit = user_project.commit(params[:sha])
        not_found!('Commit') unless commit

        find_branch!(params[:branch])

        commit_params = {
          commit: commit,
          start_branch: params[:branch],
          branch_name: params[:branch],
          dry_run: params[:dry_run],
          message: params[:message]
        }

        result = ::Commits::CherryPickService
          .new(user_project, current_user, commit_params)
          .execute

        if result[:status] == :success
          if params[:dry_run]
            present dry_run: :success
            status :ok
          else
            present user_project.repository.commit(result[:result]),
              with: Entities::Commit
          end
        else
          response = result.slice(:message, :error_code)
          response[:dry_run] = :error if params[:dry_run]

          error!(response, 400, header)
        end
      end

      desc 'Revert a commit in a branch' do
        detail 'This feature was introduced in GitLab 11.5'
        success code: 200, model: Entities::Commit
        tags %w[commits]
        failure [
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :sha, type: String, desc: 'Commit SHA to revert'
        requires :branch,
          type: String,
          desc: 'Target branch name',
          allow_blank: false,
          documentation: { example: 'master' }
        optional :dry_run, type: Boolean, default: false, desc: "Does not commit any changes"
      end
      post ':id/repository/commits/:sha/revert', requirements: API::COMMIT_ENDPOINT_REQUIREMENTS do
        authorize_push_to_branch!(params[:branch])

        commit = user_project.commit(params[:sha])
        not_found!('Commit') unless commit

        find_branch!(params[:branch])

        commit_params = {
          commit: commit,
          start_branch: params[:branch],
          branch_name: params[:branch],
          dry_run: params[:dry_run]
        }

        result = ::Commits::RevertService
          .new(user_project, current_user, commit_params)
          .execute

        if result[:status] == :success
          if params[:dry_run]
            present dry_run: :success
            status :ok
          else
            present user_project.repository.commit(result[:result]),
              with: Entities::Commit
          end
        else
          response = result.slice(:message, :error_code)
          response[:dry_run] = :error if params[:dry_run]

          error!(response, 400, header)
        end
      end

      desc 'Get all references a commit is pushed to' do
        detail 'This feature was introduced in GitLab 10.6'
        success code: 200, model: Entities::BasicRef
        tags %w[commits]
        is_array true
        failure [
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :sha, type: String, desc: 'A commit sha'
        optional :type, type: String, values: %w[branch tag all], default: 'all', desc: 'Scope'
        use :pagination
      end
      get ':id/repository/commits/:sha/refs', requirements: API::COMMIT_ENDPOINT_REQUIREMENTS, urgency: :low do
        commit = user_project.commit(params[:sha])
        not_found!('Commit') unless commit

        page = params[:page] > 0 ? params[:page] : 1
        per_page = params[:per_page] > 0 ? params[:per_page] : Kaminari.config.default_per_page

        # Gitaly RPC doesn't support pagination, but we still can limit the number of requested records
        # Example: per_page = 50, page = 3
        # Limit will be set to 151 to capture enough records for Kaminari pagination to extract the right slice.
        # 1 is added to the limit so that Kaminari knows there are more records and correctly sets the x-next-page
        # and Link headers.
        limit = ([per_page, Kaminari.config.max_per_page].min * page) + 1

        args = {
          type: declared_params[:type],
          limit: limit
        }.compact

        refs = ::Gitlab::Repositories::ContainingCommitFinder.new(
          user_project.repository,
          commit.id,
          args
        ).execute

        refs = Kaminari.paginate_array(refs)

        # Due to the limit applied above to capture just enough records, disable x-total, x-total-page, and "last" link
        # in the response header. Without this, the response headers would contain incorrect and misleading values.
        present paginate(refs, without_count: true), with: Entities::BasicRef
      end

      desc 'Post comment to commit' do
        success  code: 200, model: Entities::CommitNote
        tags %w[commits]
        failure [
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :sha, type: String, desc: 'A commit sha, or the name of a branch or tag on which to post a comment'
        requires :note,
          type: String,
          desc: 'The text of the comment',
          documentation: { example: 'Nice code!' }
        optional :path,
          type: String,
          desc: 'The file path',
          documentation: { example: 'doc/update/5.4-to-6.0.md' }
        given :path do
          requires :line,
            type: Integer,
            desc: 'The line number',
            documentation: { example: 11 }
          requires :line_type, type: String, values: %w[new old], default: 'new', desc: 'The type of the line'
        end
      end
      post ':id/repository/commits/:sha/comments', requirements: API::COMMIT_ENDPOINT_REQUIREMENTS do
        commit = user_project.commit(params[:sha])
        not_found! 'Commit' unless commit

        opts = {
          note: params[:note],
          noteable_type: 'Commit',
          commit_id: commit.id
        }

        if params[:path]
          commit.raw_diffs(limits: false).each do |diff|
            next unless diff.new_path == params[:path]

            lines = Gitlab::Diff::Parser.new.parse(diff.diff.each_line)

            lines.each do |line|
              next unless line.line == params[:line] && line.type == params[:line_type]

              break opts[:line_code] = Gitlab::Git.diff_line_code(diff.new_path, line.new_pos, line.old_pos)
            end

            break if opts[:line_code]
          end

          opts[:type] = LegacyDiffNote.name if opts[:line_code]
        end

        note = ::Notes::CreateService.new(user_project, current_user, opts).execute

        process_note_creation_result(note) do
          present note, with: Entities::CommitNote
        end
      end

      desc 'Get Merge Requests associated with a commit' do
        success code: 200, model: Entities::MergeRequestBasic
        tags %w[commits]
        is_array true
        failure [
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :sha, type: String, desc: 'A commit sha, or the name of a branch or tag on which to find Merge Requests'
        optional :state, type: String, desc: 'Filter merge-requests by state', documentation: { example: 'merged' }
        use :pagination
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: :read_repositories,
        allow_public_access_for_enabled_project_features: [:repository, :merge_requests]
      get ':id/repository/commits/:sha/merge_requests', requirements: API::COMMIT_ENDPOINT_REQUIREMENTS, urgency: :low do
        authorize! :read_merge_request, user_project

        commit = user_project.commit(params[:sha])
        not_found! 'Commit' unless commit

        commit_merge_requests = MergeRequestsFinder.new(
          current_user,
          project_id: user_project.id,
          commit_sha: commit.sha,
          state: params[:state]
        ).execute.with_api_entity_associations

        present paginate(commit_merge_requests), with: Entities::MergeRequestBasic
      end

      desc "Get a commit's signature" do
        success code: 200, model: Entities::CommitSignature
        tags %w[commits]
        failure [
          { code: 404, message: 'Not found' }
        ]
      end
      params do
        requires :sha, type: String, desc: 'A commit sha, or the name of a branch or tag'
      end
      get ':id/repository/commits/:sha/signature', requirements: API::COMMIT_ENDPOINT_REQUIREMENTS do
        commit = user_project.commit(params[:sha])
        not_found! 'Commit' unless commit
        not_found! 'Signature' unless commit.has_signature?

        present commit, with: Entities::CommitSignature
      end
    end
  end
end
