module API
  class MergeRequests < Grape::API
    include PaginationParams

    before { authenticate_non_get! }

    helpers ::Gitlab::IssuableMetadata

    # EE::API::MergeRequests would override the following helpers
    helpers do
      params :optional_params_ee do
      end

      params :merge_params_ee do
      end

      def update_merge_request_ee(merge_request)
      end
    end

    def self.update_params_at_least_one_of
      %i[
        assignee_id
        description
        labels
        milestone_id
        remove_source_branch
        state_event
        target_branch
        title
        discussion_locked
      ]
    end

    prepend EE::API::MergeRequests

    helpers do
      def find_merge_requests(args = {})
        args = declared_params.merge(args)

        args[:milestone_title] = args.delete(:milestone)
        args[:label_name] = args.delete(:labels)

        merge_requests = MergeRequestsFinder.new(current_user, args).execute
                           .reorder(args[:order_by] => args[:sort])
        merge_requests = paginate(merge_requests)
                           .preload(:target_project)

        return merge_requests if args[:view] == 'simple'

        merge_requests
          .preload(:notes, :author, :assignee, :milestone, :latest_merge_request_diff, :labels, :timelogs)
      end

      def merge_request_pipelines_with_access
        authorize! :read_pipeline, user_project

        mr = find_merge_request_with_access(params[:merge_request_iid])
        mr.all_pipelines
      end

      def check_sha_param!(params, merge_request)
        if params[:sha] && merge_request.diff_head_sha != params[:sha]
          render_api_error!("SHA does not match HEAD of source branch: #{merge_request.diff_head_sha}", 409)
        end
      end

      params :merge_requests_params do
        optional :state, type: String, values: %w[opened closed merged all], default: 'all',
                         desc: 'Return opened, closed, merged, or all merge requests'
        optional :order_by, type: String, values: %w[created_at updated_at], default: 'created_at',
                            desc: 'Return merge requests ordered by `created_at` or `updated_at` fields.'
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
                        desc: 'Return merge requests sorted in `asc` or `desc` order.'
        optional :milestone, type: String, desc: 'Return merge requests for a specific milestone'
        optional :labels, type: String, desc: 'Comma-separated list of label names'
        optional :created_after, type: DateTime, desc: 'Return merge requests created after the specified time'
        optional :created_before, type: DateTime, desc: 'Return merge requests created before the specified time'
        optional :updated_after, type: DateTime, desc: 'Return merge requests updated after the specified time'
        optional :updated_before, type: DateTime, desc: 'Return merge requests updated before the specified time'
        optional :view, type: String, values: %w[simple], desc: 'If simple, returns the `iid`, URL, title, description, and basic state of merge request'
        optional :author_id, type: Integer, desc: 'Return merge requests which are authored by the user with the given ID'
        optional :assignee_id, type: Integer, desc: 'Return merge requests which are assigned to the user with the given ID'
        optional :scope, type: String, values: %w[created-by-me assigned-to-me all],
                         desc: 'Return merge requests for the given scope: `created-by-me`, `assigned-to-me` or `all`'
        optional :my_reaction_emoji, type: String, desc: 'Return issues reacted by the authenticated user by the given emoji'
        optional :source_branch, type: String, desc: 'Return merge requests with the given source branch'
        optional :target_branch, type: String, desc: 'Return merge requests with the given target branch'
        optional :search, type: String, desc: 'Search merge requests for text present in the title or description'
        use :pagination
      end
    end

    resource :merge_requests do
      desc 'List merge requests' do
        success Entities::MergeRequestBasic
      end
      params do
        use :merge_requests_params
        optional :scope, type: String, values: %w[created-by-me assigned-to-me all], default: 'created-by-me',
                         desc: 'Return merge requests for the given scope: `created-by-me`, `assigned-to-me` or `all`'
      end
      get do
        authenticate! unless params[:scope] == 'all'
        merge_requests = find_merge_requests

        options = { with: Entities::MergeRequestBasic,
                    current_user: current_user }

        if params[:view] == 'simple'
          options[:with] = Entities::MergeRequestSimple
        else
          options[:issuable_metadata] = issuable_meta_data(merge_requests, 'MergeRequest')
        end

        present merge_requests, options
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      include TimeTrackingEndpoints

      helpers do
        def handle_merge_request_errors!(errors)
          if errors[:project_access].any?
            error!(errors[:project_access], 422)
          elsif errors[:branch_conflict].any?
            error!(errors[:branch_conflict], 422)
          elsif errors[:validate_fork].any?
            error!(errors[:validate_fork], 422)
          elsif errors[:validate_branches].any?
            conflict!(errors[:validate_branches])
          elsif errors[:base].any?
            error!(errors[:base], 422)
          end

          render_api_error!(errors, 400)
        end

        params :optional_params do
          optional :description, type: String, desc: 'The description of the merge request'
          optional :assignee_id, type: Integer, desc: 'The ID of a user to assign the merge request'
          optional :milestone_id, type: Integer, desc: 'The ID of a milestone to assign the merge request'
          optional :labels, type: String, desc: 'Comma-separated list of label names'
          optional :remove_source_branch, type: Boolean, desc: 'Remove source branch when merging'
          optional :allow_maintainer_to_push, type: Boolean, desc: 'Whether a maintainer of the target project can push to the source project'

          use :optional_params_ee
        end
      end

      desc 'List merge requests' do
        success Entities::MergeRequestBasic
      end
      params do
        use :merge_requests_params
        optional :iids, type: Array[Integer], desc: 'The IID array of merge requests'
      end
      get ":id/merge_requests" do
        authorize! :read_merge_request, user_project

        merge_requests = find_merge_requests(project_id: user_project.id)

        options = { with: Entities::MergeRequestBasic,
                    current_user: current_user,
                    project: user_project }

        if params[:view] == 'simple'
          options[:with] = Entities::MergeRequestSimple
        else
          options[:issuable_metadata] = issuable_meta_data(merge_requests, 'MergeRequest')
        end

        present merge_requests, options
      end

      desc 'Create a merge request' do
        success Entities::MergeRequest
      end
      params do
        requires :title, type: String, desc: 'The title of the merge request'
        requires :source_branch, type: String, desc: 'The source branch'
        requires :target_branch, type: String, desc: 'The target branch'
        optional :target_project_id, type: Integer,
                                     desc: 'The target project of the merge request defaults to the :id of the project'
        use :optional_params
      end
      post ":id/merge_requests" do
        Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42316')

        authorize! :create_merge_request_from, user_project

        mr_params = declared_params(include_missing: false)
        mr_params[:force_remove_source_branch] = mr_params.delete(:remove_source_branch)

        merge_request = ::MergeRequests::CreateService.new(user_project, current_user, mr_params).execute

        if merge_request.valid?
          present merge_request, with: Entities::MergeRequest, current_user: current_user, project: user_project
        else
          handle_merge_request_errors! merge_request.errors
        end
      end

      desc 'Delete a merge request'
      params do
        requires :merge_request_iid, type: Integer, desc: 'The IID of a merge request'
      end
      delete ":id/merge_requests/:merge_request_iid" do
        merge_request = find_project_merge_request(params[:merge_request_iid])

        authorize!(:destroy_merge_request, merge_request)

        destroy_conditionally!(merge_request) do |merge_request|
          Issuable::DestroyService.new(user_project, current_user).execute(merge_request)
        end
      end

      params do
        requires :merge_request_iid, type: Integer, desc: 'The IID of a merge request'
      end
      desc 'Get a single merge request' do
        success Entities::MergeRequest
      end
      get ':id/merge_requests/:merge_request_iid' do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        present merge_request, with: Entities::MergeRequest, current_user: current_user, project: user_project
      end

      desc 'Get the participants of a merge request' do
        success Entities::UserBasic
      end
      get ':id/merge_requests/:merge_request_iid/participants' do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])
        participants = ::Kaminari.paginate_array(merge_request.participants)

        present paginate(participants), with: Entities::UserBasic
      end

      desc 'Get the commits of a merge request' do
        success Entities::Commit
      end
      get ':id/merge_requests/:merge_request_iid/commits' do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])
        commits = ::Kaminari.paginate_array(merge_request.commits)

        present paginate(commits), with: Entities::Commit
      end

      desc 'Show the merge request changes' do
        success Entities::MergeRequestChanges
      end
      get ':id/merge_requests/:merge_request_iid/changes' do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        present merge_request, with: Entities::MergeRequestChanges, current_user: current_user, project: user_project
      end

      desc 'Get the merge request pipelines' do
        success Entities::PipelineBasic
      end
      get ':id/merge_requests/:merge_request_iid/pipelines' do
        pipelines = merge_request_pipelines_with_access

        present paginate(pipelines), with: Entities::PipelineBasic
      end

      desc 'Update a merge request' do
        success Entities::MergeRequest
      end
      params do
        optional :title, type: String, allow_blank: false, desc: 'The title of the merge request'
        optional :target_branch, type: String, allow_blank: false, desc: 'The target branch'
        optional :state_event, type: String, values: %w[close reopen],
                               desc: 'Status of the merge request'
        optional :discussion_locked, type: Boolean, desc: 'Whether the MR discussion is locked'

        use :optional_params
        at_least_one_of(*::API::MergeRequests.update_params_at_least_one_of)
      end
      put ':id/merge_requests/:merge_request_iid' do
        Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42318')

        merge_request = find_merge_request_with_access(params.delete(:merge_request_iid), :update_merge_request)

        mr_params = declared_params(include_missing: false)
        mr_params[:force_remove_source_branch] = mr_params.delete(:remove_source_branch) if mr_params[:remove_source_branch].present?

        merge_request = ::MergeRequests::UpdateService.new(user_project, current_user, mr_params).execute(merge_request)

        if merge_request.valid?
          present merge_request, with: Entities::MergeRequest, current_user: current_user, project: user_project
        else
          handle_merge_request_errors! merge_request.errors
        end
      end

      desc 'Merge a merge request' do
        success Entities::MergeRequest
      end
      params do
        optional :merge_commit_message, type: String, desc: 'Custom merge commit message'
        optional :should_remove_source_branch, type: Boolean,
                                               desc: 'When true, the source branch will be deleted if possible'
        optional :merge_when_pipeline_succeeds, type: Boolean,
                                                desc: 'When true, this merge request will be merged when the pipeline succeeds'
        optional :sha, type: String, desc: 'When present, must have the HEAD SHA of the source branch'

        use :merge_params_ee
      end
      put ':id/merge_requests/:merge_request_iid/merge' do
        Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42317')

        merge_request = find_project_merge_request(params[:merge_request_iid])
        merge_when_pipeline_succeeds = to_boolean(params[:merge_when_pipeline_succeeds])

        # Merge request can not be merged
        # because user dont have permissions to push into target branch
        unauthorized! unless merge_request.can_be_merged_by?(current_user)

        not_allowed! unless merge_request.mergeable_state?(skip_ci_check: merge_when_pipeline_succeeds)

        render_api_error!('Branch cannot be merged', 406) unless merge_request.mergeable?(skip_ci_check: merge_when_pipeline_succeeds)

        check_sha_param!(params, merge_request)

        update_merge_request_ee(merge_request)

        merge_params = {
          commit_message: params[:merge_commit_message],
          should_remove_source_branch: params[:should_remove_source_branch]
        }

        if merge_when_pipeline_succeeds && merge_request.head_pipeline && merge_request.head_pipeline.active?
          ::MergeRequests::MergeWhenPipelineSucceedsService
            .new(merge_request.target_project, current_user, merge_params)
            .execute(merge_request)
        else
          ::MergeRequests::MergeService
            .new(merge_request.target_project, current_user, merge_params)
            .execute(merge_request)
        end

        present merge_request, with: Entities::MergeRequest, current_user: current_user, project: user_project
      end

      desc 'Cancel merge if "Merge When Pipeline Succeeds" is enabled' do
        success Entities::MergeRequest
      end
      post ':id/merge_requests/:merge_request_iid/cancel_merge_when_pipeline_succeeds' do
        merge_request = find_project_merge_request(params[:merge_request_iid])

        unauthorized! unless merge_request.can_cancel_merge_when_pipeline_succeeds?(current_user)

        ::MergeRequests::MergeWhenPipelineSucceedsService
          .new(merge_request.target_project, current_user)
          .cancel(merge_request)
      end

      desc 'List issues that will be closed on merge' do
        success Entities::MRNote
      end
      params do
        use :pagination
      end
      get ':id/merge_requests/:merge_request_iid/closes_issues' do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])
        issues = ::Kaminari.paginate_array(merge_request.closes_issues(current_user))
        issues = paginate(issues)

        external_issues, internal_issues = issues.partition { |issue| issue.is_a?(ExternalIssue) }

        data = Entities::IssueBasic.represent(internal_issues, current_user: current_user)
        data += Entities::ExternalIssue.represent(external_issues, current_user: current_user)

        data.as_json
      end
    end
  end
end
