# frozen_string_literal: true

module API
  class IssueLinks < ::API::Base
    include PaginationParams

    before { authenticate! }

    feature_category :issue_tracking

    params do
      requires :id, type: String, desc: 'The ID of a project'
      requires :issue_iid, type: Integer, desc: 'The internal ID of a project issue'
    end
    resource :projects, requirements: { id: %r{[^/]+} } do
      desc 'Get related issues' do
        success Entities::RelatedIssue
      end
      get ':id/issues/:issue_iid/links' do
        source_issue = find_project_issue(params[:issue_iid])
        related_issues = source_issue.related_issues(current_user) do |issues|
          issues.with_api_entity_associations.preload_awardable
        end

        present related_issues,
                with: Entities::RelatedIssue,
                current_user: current_user,
                project: user_project,
                include_subscribed: false
      end

      desc 'Relate issues' do
        success Entities::IssueLink
      end
      params do
        requires :target_project_id, type: String, desc: 'The ID of the target project'
        requires :target_issue_iid, type: Integer, desc: 'The IID of the target issue'
        optional :link_type, type: String, values: IssueLink.link_types.keys,
          desc: 'The type of the relation'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post ':id/issues/:issue_iid/links' do
        source_issue = find_project_issue(params[:issue_iid])
        target_issue = find_project_issue(declared_params[:target_issue_iid],
                                          declared_params[:target_project_id])

        create_params = { target_issuable: target_issue, link_type: declared_params[:link_type] }

        result = ::IssueLinks::CreateService
                   .new(source_issue, current_user, create_params)
                   .execute

        if result[:status] == :success
          issue_link = IssueLink.find_by!(source: source_issue, target: target_issue)

          present issue_link, with: Entities::IssueLink
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Remove issues relation' do
        success Entities::IssueLink
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
          present issue_link, with: Entities::IssueLink
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end
    end
  end
end
