module API
  class IssueLinks < Grape::API
    include PaginationParams

    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The ID of a project'
      requires :issue_iid, type: Integer, desc: 'The internal ID of a project issue'
    end
    resource :projects, requirements: { id: %r{[^/]+} } do
      desc 'Get related issues' do
        success EE::API::Entities::RelatedIssue
      end
      get ':id/issues/:issue_iid/links' do
        source_issue = find_project_issue(params[:issue_iid])
        related_issues = source_issue.related_issues(current_user)

        present related_issues,
                with: EE::API::Entities::RelatedIssue,
                current_user: current_user,
                project: user_project
      end

      desc 'Relate issues' do
        success EE::API::Entities::IssueLink
      end
      params do
        requires :target_project_id, type: String, desc: 'The ID of the target project'
        requires :target_issue_iid, type: Integer, desc: 'The IID of the target issue'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post ':id/issues/:issue_iid/links' do
        source_issue = find_project_issue(params[:issue_iid])
        target_issue = find_project_issue(declared_params[:target_issue_iid],
                                          declared_params[:target_project_id])

        create_params = { target_issue: target_issue }

        result = ::IssueLinks::CreateService
                   .new(source_issue, current_user, create_params)
                   .execute

        if result[:status] == :success
          issue_link = IssueLink.find_by!(source: source_issue, target: target_issue)

          present issue_link, with: EE::API::Entities::IssueLink
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Remove issues relation' do
        success EE::API::Entities::IssueLink
      end
      params do
        requires :issue_link_id, type: Integer, desc: 'The ID of an issue link'
      end
      delete ':id/issues/:issue_iid/links/:issue_link_id' do
        issue_link = IssueLink.find(declared_params[:issue_link_id])

        find_project_issue(params[:issue_iid])
        find_project_issue(issue_link.target.iid.to_s, issue_link.target.project_id.to_s)

        result = ::IssueLinks::DestroyService
                   .new(issue_link, current_user)
                   .execute

        if result[:status] == :success
          present issue_link, with: EE::API::Entities::IssueLink
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end
    end
  end
end
