# These endpoints partially mimic Github API behavior in order to successfully
# integrate with Jira Development Panel.
# Endpoints returning an empty list were temporarily added to avoid 404's
# during Jira's DVCS integration.
#
module API
  module V3
    class Github < Grape::API
      JIRA_DEV_PANEL_FEATURE = :jira_dev_panel_integration.freeze
      NO_SLASH_URL_PART_REGEX = %r{[^/]+}
      NAMESPACE_ENDPOINT_REQUIREMENTS = { namespace: NO_SLASH_URL_PART_REGEX }.freeze
      PROJECT_ENDPOINT_REQUIREMENTS = NAMESPACE_ENDPOINT_REQUIREMENTS.merge(project: NO_SLASH_URL_PART_REGEX).freeze

      include PaginationParams

      before do
        authorize_jira_user_agent!(request)
        authenticate!
      end

      helpers do
        params :project_full_path do
          requires :namespace, type: String
          requires :project, type: String
        end

        def authorize_jira_user_agent!(request)
          not_found! unless Gitlab::Jira::Middleware.jira_dvcs_connector?(request.env)
        end

        def find_project_with_access(params)
          project = find_project!(
            ::Gitlab::Jira::Dvcs.restore_full_path(params.slice(:namespace, :project).symbolize_keys)
          )
          not_found! unless licensed_project?(project)
          project
        end

        def find_merge_requests
          merge_requests = authorized_merge_requests.reorder(updated_at: :desc).preload(:target_project)
          merge_requests = paginate(merge_requests)
          merge_requests.select { |mr| licensed_project?(mr.target_project) }
        end

        def find_merge_request_with_access(id, access_level = :read_merge_request)
          merge_request = authorized_merge_requests.find_by(id: id)
          not_found! unless can?(current_user, access_level, merge_request)
          merge_request
        end

        def authorized_merge_requests
          MergeRequestsFinder.new(current_user, authorized_only: true).execute
        end

        def find_notes(noteable)
          # They're not presented on Jira Dev Panel ATM. A comments count with a
          # redirect link is presented.
          notes = paginate(noteable.notes.user.reorder(nil))
          notes.reject { |n| n.cross_reference_not_visible_for?(current_user) }
        end

        def licensed_project?(project)
          project.feature_available?(JIRA_DEV_PANEL_FEATURE)
        end
      end

      resource :orgs do
        get ':namespace/repos', requirements: NAMESPACE_ENDPOINT_REQUIREMENTS do
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
        get ':namespace/repos', requirements: NAMESPACE_ENDPOINT_REQUIREMENTS do
          namespace = Namespace.find_by_full_path(params[:namespace])
          not_found!('Namespace') unless namespace

          projects = current_user.authorized_projects.where(namespace_id: namespace.self_and_descendants).to_a
          projects.select! { |project| licensed_project?(project) }
          projects = ::Kaminari.paginate_array(projects)
          present paginate(projects), with: ::API::Github::Entities::Repository
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

        params do
          use :project_full_path
        end
        get ':namespace/:project/pulls', requirements: PROJECT_ENDPOINT_REQUIREMENTS do
          user_project = find_project_with_access(params)

          merge_requests = MergeRequestsFinder.new(current_user, authorized_only: true, project_id: user_project.id).execute

          present paginate(merge_requests), with: ::API::Github::Entities::PullRequest
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
        # We need to respond with a 200 request to avoid breaking the
        # integration flow (fetching merge requests).
        get ':namespace/:project/events' do
          present []
        end

        params do
          use :project_full_path
          use :pagination
        end
        get ':namespace/:project/branches', requirements: PROJECT_ENDPOINT_REQUIREMENTS do
          user_project = find_project_with_access(params)

          branches = ::Kaminari.paginate_array(user_project.repository.branches.sort_by(&:name))

          present paginate(branches), with: ::API::Github::Entities::Branch, project: user_project
        end

        params do
          use :project_full_path
        end
        get ':namespace/:project/commits/:sha', requirements: PROJECT_ENDPOINT_REQUIREMENTS do
          user_project = find_project_with_access(params)

          commit = user_project.commit(params[:sha])

          not_found! 'Commit' unless commit

          present commit, with: ::API::Github::Entities::RepoCommit
        end
      end
    end
  end
end
