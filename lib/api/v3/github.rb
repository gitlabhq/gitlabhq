# frozen_string_literal: true

# The endpoints by default return `404` in preparation for their removal
# (also see comment above `#reversible_end_of_life!`).
# https://gitlab.com/gitlab-org/gitlab/-/issues/362168
#
# These endpoints partially mimic Github API behavior in order to successfully
# integrate with Jira Development Panel.
module API
  module V3
    class Github < ::API::Base
      NO_SLASH_URL_PART_REGEX = %r{[^/]+}.freeze
      ENDPOINT_REQUIREMENTS = {
        namespace: NO_SLASH_URL_PART_REGEX,
        project: NO_SLASH_URL_PART_REGEX,
        username: NO_SLASH_URL_PART_REGEX
      }.freeze

      # Used to differentiate Jira Cloud requests from Jira Server requests
      # Jira Cloud user agent format: Jira DVCS Connector Vertigo/version
      # Jira Server user agent format: Jira DVCS Connector/version
      JIRA_DVCS_CLOUD_USER_AGENT = 'Jira DVCS Connector Vertigo'

      GITALY_TIMEOUT_CACHE_KEY = 'api:v3:Gitaly-timeout-cache-key'
      GITALY_TIMEOUT_CACHE_EXPIRY = 1.day

      include PaginationParams

      feature_category :integrations

      before do
        reversible_end_of_life!

        authorize_jira_user_agent!(request)
        authenticate!
      end

      helpers do
        params :project_full_path do
          requires :namespace, type: String
          requires :project, type: String
        end

        # The endpoints in this class have been deprecated since 15.1.
        #
        # Due to uncertainty about the impact of a full removal in 16.0, all endpoints return `404`
        # by default but we allow customers to toggle a flag to reverse this breaking change.
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/362168#note_1347692683.
        #
        # TODO Make the breaking change irreversible https://gitlab.com/gitlab-org/gitlab/-/issues/408148.
        def reversible_end_of_life!
          not_found! unless Feature.enabled?(:jira_dvcs_end_of_life_amnesty)
        end

        def authorize_jira_user_agent!(request)
          not_found! unless Gitlab::Jira::Middleware.jira_dvcs_connector?(request.env)
        end

        def update_project_feature_usage_for(project)
          # Prevent errors on GitLab Geo not allowing
          # UPDATE statements to happen in GET requests.
          return if Gitlab::Database.read_only?

          project.log_jira_dvcs_integration_usage(cloud: jira_cloud?)
        end

        def jira_cloud?
          request.env['HTTP_USER_AGENT'].include?(JIRA_DVCS_CLOUD_USER_AGENT)
        end

        def find_project_with_access(params)
          project = find_project!(
            ::Gitlab::Jira::Dvcs.restore_full_path(**params.slice(:namespace, :project).symbolize_keys)
          )
          not_found! unless can?(current_user, :read_code, project)
          project
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def find_merge_requests
          merge_requests = authorized_merge_requests.reorder(updated_at: :desc)
          paginate(merge_requests)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def find_merge_request_with_access(id, access_level = :read_merge_request)
          merge_request = authorized_merge_requests.find_by(id: id)
          not_found! unless can?(current_user, access_level, merge_request)
          merge_request
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def authorized_merge_requests
          MergeRequestsFinder.new(current_user, authorized_only: !current_user.can_read_all_resources?)
            .execute.with_jira_integration_associations
        end

        def authorized_merge_requests_for_project(project)
          MergeRequestsFinder
            .new(current_user, authorized_only: !current_user.can_read_all_resources?, project_id: project.id)
            .execute.with_jira_integration_associations
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def find_notes(noteable)
          # They're not presented on Jira Dev Panel ATM. A comments count with a
          # redirect link is presented.
          notes = paginate(noteable.notes.user.reorder(nil))
          notes.select { |n| n.readable_by?(current_user) }
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # Returns an empty Array instead of the Commit diff files for a period
        # of time after a Gitaly timeout, to mitigate frequent Gitaly timeouts
        # for some Commit diffs.
        def diff_files(commit)
          cache_key = [
            GITALY_TIMEOUT_CACHE_KEY,
            commit.project.id,
            commit.cache_key
          ].join(':')

          return [] if Rails.cache.read(cache_key).present?

          begin
            commit.diffs.diff_files
          rescue GRPC::DeadlineExceeded => error
            # Gitaly fails to load diffs consistently for some commits. The other information
            # is still valuable for Jira. So we skip the loading and respond with a 200 excluding diffs
            # Remove this when https://gitlab.com/gitlab-org/gitaly/-/issues/3741 is fixed.
            Rails.cache.write(cache_key, 1, expires_in: GITALY_TIMEOUT_CACHE_EXPIRY)
            Gitlab::ErrorTracking.track_exception(error)
            []
          end
        end
      end

      resource :orgs do
        get ':namespace/repos' do
          present []
        end
      end

      resource :user do
        get :repos do
          present []
        end
      end

      resource :users do
        params do
          use :pagination
        end

        get ':namespace/repos' do
          namespace = Namespace.find_by_full_path(params[:namespace])
          not_found!('Namespace') unless namespace

          projects = current_user.can_read_all_resources? ? Project.all : current_user.authorized_projects
          projects = projects.in_namespace(namespace.self_and_descendants)

          projects_cte = Project.wrap_with_cte(projects)
                                .eager_load_namespace_and_owner
                                .with_route

          present paginate(projects_cte),
                  with: ::API::Github::Entities::Repository,
                  root_namespace: namespace.root_ancestor
        end

        get ':username' do
          forbidden! unless can?(current_user, :read_users_list)
          user = UsersFinder.new(current_user, { username: params[:username] }).execute.first
          not_found! unless user
          present user, with: ::API::Github::Entities::User
        end
      end

      # Jira dev panel integration weirdly requests for "/-/jira/pulls" instead
      # "/api/v3/repos/<namespace>/<project>/pulls". This forces us into
      # returning _all_ Merge Requests from authorized projects (user is a member),
      # instead just the authorized MRs from a project.
      # Jira handles the filtering, presenting just MRs mentioning the Jira
      # issue ID on the MR title / description.
      resource :repos do
        # Keeping for backwards compatibility with old Jira integration instructions
        # so that users that do not change it will not suddenly have a broken integration
        get '/-/jira/pulls' do
          present find_merge_requests, with: ::API::Github::Entities::PullRequest
        end

        get '/-/jira/events' do
          present []
        end

        params do
          use :project_full_path
        end
        # TODO Remove the custom Apdex SLO target `urgency: :low` when this endpoint has been optimised.
        # https://gitlab.com/gitlab-org/gitlab/-/issues/337269
        get ':namespace/:project/pulls', urgency: :low do
          user_project = find_project_with_access(params)

          merge_requests = authorized_merge_requests_for_project(user_project)

          present paginate(merge_requests), with: ::API::Github::Entities::PullRequest
        end

        params do
          use :project_full_path
        end
        get ':namespace/:project/pulls/:id' do
          merge_request = find_merge_request_with_access(params[:id])

          present merge_request, with: ::API::Github::Entities::PullRequest
        end

        # In Github, each Merge Request is automatically also an issue.
        # Therefore we return its comments here.
        # It'll present _just_ the comments counting with a link to GitLab on
        # Jira dev panel, not the actual note content.
        get ':namespace/:project/issues/:id/comments' do
          merge_request = find_merge_request_with_access(params[:id])

          present find_notes(merge_request), with: ::API::Github::Entities::NoteableComment
        end

        # This refer to "review" comments but Jira dev panel doesn't seem to
        # present it accordingly.
        get ':namespace/:project/pulls/:id/comments' do
          present []
        end

        # Commits are not presented within "Pull Requests" modal on Jira dev
        # panel.
        get ':namespace/:project/pulls/:id/commits' do
          present []
        end

        # Self-hosted Jira (tested on 7.11.1) requests this endpoint right
        # after fetching branches.
        get ':namespace/:project/events' do
          user_project = find_project_with_access(params)

          merge_requests = authorized_merge_requests_for_project(user_project)

          present paginate(merge_requests), with: ::API::Github::Entities::PullRequestEvent
        end

        params do
          use :project_full_path
          use :pagination
        end
        # TODO Remove the custom Apdex SLO target `urgency: :low` when this endpoint has been optimised.
        # https://gitlab.com/gitlab-org/gitlab/-/issues/337268
        get ':namespace/:project/branches', urgency: :low do
          user_project = find_project_with_access(params)

          update_project_feature_usage_for(user_project)

          next [] unless user_project.repo_exists?

          branches = ::Kaminari.paginate_array(user_project.repository.branches.sort_by(&:name))

          present paginate(branches), with: ::API::Github::Entities::Branch, project: user_project
        end

        params do
          use :project_full_path
        end
        get ':namespace/:project/commits/:sha' do
          user_project = find_project_with_access(params)

          commit = user_project.commit(params[:sha])
          not_found! 'Commit' unless commit

          present commit, with: ::API::Github::Entities::RepoCommit, diff_files: diff_files(commit)
        end
      end
    end
  end
end
