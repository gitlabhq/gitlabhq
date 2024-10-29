# frozen_string_literal: true

module API
  class IssueLinks < ::API::Base
    include PaginationParams

    before { authenticate! }

    ISSUE_LINKS_TAGS = %w[issue_links].freeze

    feature_category :team_planning
    urgency :low

    params do
      requires :id, types: [String, Integer],
        desc: 'The ID or URL-encoded path of the project owned by the authenticated user'
      requires :issue_iid, type: Integer, desc: 'The internal ID of a project’s issue'
    end
    resource :projects, requirements: { id: %r{[^/]+} } do
      desc 'List issue relations' do
        detail 'Get a list of a given issue’s linked issues, sorted by the relationship creation datetime (ascending).'\
          'Issues are filtered according to the user authorizations.'
        success Entities::RelatedIssue
        is_array true
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags ISSUE_LINKS_TAGS
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

      desc 'Create an issue link' do
        detail 'Creates a two-way relation between two issues.'\
          'The user must be allowed to update both issues to succeed.'
        success Entities::IssueLink
        failure [
          { code: 400, message: 'Bad Request' },
          { code: 401, message: 'Unauthorized' }
        ]
        tags ISSUE_LINKS_TAGS
      end
      params do
        requires :target_project_id, types: [String, Integer],
          desc: 'The ID or URL-encoded path of a target project'
        requires :target_issue_iid, types: [String, Integer], desc: 'The internal ID of a target project’s issue'
        optional :link_type, type: String, values: IssueLink.available_link_types,
          desc: 'The type of the relation (“relates_to”, “blocks”, “is_blocked_by”),'\
           'defaults to “relates_to”)'
      end
      post ':id/issues/:issue_iid/links' do
        source_issue = find_project_issue(params[:issue_iid])
        target_issue = find_project_issue(declared_params[:target_issue_iid],
          declared_params[:target_project_id])

        create_params = { target_issuable: target_issue, link_type: declared_params[:link_type] }

        result = ::IssueLinks::CreateService
                   .new(source_issue, current_user, create_params)
                   .execute

        if result[:status] == :success
          present result[:created_references].first, with: Entities::IssueLink
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end
      desc 'Get an issue link' do
        detail 'Gets details about an issue link. This feature was introduced in GitLab 15.1.'
        success Entities::IssueLink
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags ISSUE_LINKS_TAGS
      end
      params do
        requires :issue_link_id, types: [String, Integer], desc: 'ID of an issue relationship'
      end
      get ':id/issues/:issue_iid/links/:issue_link_id' do
        issue = find_project_issue(params[:issue_iid])
        issue_link = IssueLink.for_source_or_target(issue).find(declared_params[:issue_link_id])

        find_project_issue(issue_link.target.iid.to_s, issue_link.target.project_id.to_s)

        present issue_link, with: Entities::IssueLink
      end

      desc 'Delete an issue link' do
        detail 'Deletes an issue link, thus removes the two-way relationship.'
        success Entities::IssueLink
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags ISSUE_LINKS_TAGS
      end
      params do
        requires :issue_link_id, types: [String, Integer], desc: 'The ID of an issue relationship'
      end
      delete ':id/issues/:issue_iid/links/:issue_link_id' do
        issue = find_project_issue(params[:issue_iid])
        issue_link = IssueLink
          .for_source_or_target(issue)
          .find(declared_params[:issue_link_id])

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
