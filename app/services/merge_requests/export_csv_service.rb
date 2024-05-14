# frozen_string_literal: true

module MergeRequests
  class ExportCsvService < ExportCsv::BaseService
    include Gitlab::Routing.url_helpers
    include GitlabRoutingHelper

    def email(user)
      Notify.merge_requests_csv_email(user, resource_parent, csv_data, csv_builder.status).deliver_now
    end

    private

    def header_to_value_hash
      {
        'Title' => 'title',
        'Description' => 'description',
        'MR IID' => 'iid',
        'URL' => ->(merge_request) { merge_request_url(merge_request) },
        'State' => 'state',
        'Source Branch' => 'source_branch',
        'Target Branch' => 'target_branch',
        'Source Project ID' => 'source_project_id',
        'Target Project ID' => 'target_project_id',
        'Author' => ->(merge_request) { merge_request.author.name },
        'Author Username' => ->(merge_request) { merge_request.author.username },
        'Assignees' => ->(merge_request) { merge_request.assignees.map(&:name).join(', ') },
        'Assignee Usernames' => ->(merge_request) { merge_request.assignees.map(&:username).join(', ') },
        'Approvers' => ->(merge_request) { merge_request.approved_by_users.map(&:name).join(', ') },
        'Approver Usernames' => ->(merge_request) { merge_request.approved_by_users.map(&:username).join(', ') },
        'Merged User' => ->(merge_request) { merge_request.metrics&.merged_by&.name.to_s },
        'Merged Username' => ->(merge_request) { merge_request.metrics&.merged_by&.username.to_s },
        'Milestone ID' => ->(merge_request) { merge_request&.milestone&.id || '' },
        'Created At (UTC)' => ->(merge_request) { merge_request.created_at.utc },
        'Updated At (UTC)' => ->(merge_request) { merge_request.updated_at.utc }
      }
    end
  end
end
