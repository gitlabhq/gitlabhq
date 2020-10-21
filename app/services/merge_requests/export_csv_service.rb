# frozen_string_literal: true

module MergeRequests
  class ExportCsvService
    include Gitlab::Routing.url_helpers
    include GitlabRoutingHelper

    # Target attachment size before base64 encoding
    TARGET_FILESIZE = 15.megabytes

    def initialize(merge_requests, project)
      @project = project
      @merge_requests = merge_requests
    end

    def csv_data
      csv_builder.render(TARGET_FILESIZE)
    end

    def email(user)
      Notify.merge_requests_csv_email(user, @project, csv_data, csv_builder.status).deliver_now
    end

    private

    def csv_builder
      @csv_builder ||= CsvBuilder.new(@merge_requests.with_csv_entity_associations, header_to_value_hash)
    end

    def header_to_value_hash
      {
        'MR IID' => 'iid',
        'URL' => -> (merge_request) { merge_request_url(merge_request) },
        'Title' => 'title',
        'State' => 'state',
        'Description' => 'description',
        'Source Branch' => 'source_branch',
        'Target Branch' => 'target_branch',
        'Source Project ID' => 'source_project_id',
        'Target Project ID' => 'target_project_id',
        'Author' => -> (merge_request) { merge_request.author.name },
        'Author Username' => -> (merge_request) { merge_request.author.username },
        'Assignees' => -> (merge_request) { merge_request.assignees.map(&:name).join(', ') },
        'Assignee Usernames' => -> (merge_request) { merge_request.assignees.map(&:username).join(', ') },
        'Approvers' => -> (merge_request) { merge_request.approved_by_users.map(&:name).join(', ') },
        'Approver Usernames' => -> (merge_request) { merge_request.approved_by_users.map(&:username).join(', ') },
        'Merged User' => -> (merge_request) { merge_request.metrics&.merged_by&.name.to_s },
        'Merged Username' => -> (merge_request) { merge_request.metrics&.merged_by&.username.to_s },
        'Milestone ID' => -> (merge_request) { merge_request&.milestone&.id || '' },
        'Created At (UTC)' => -> (merge_request) { merge_request.created_at.utc },
        'Updated At (UTC)' => -> (merge_request) { merge_request.updated_at.utc }
      }
    end
  end
end
