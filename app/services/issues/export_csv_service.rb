# frozen_string_literal: true

module Issues
  class ExportCsvService < Issuable::ExportCsv::BaseService
    include Gitlab::Routing.url_helpers
    include GitlabRoutingHelper

    def initialize(issuables_relation, project)
      super

      @labels = @issuables.labels_hash.transform_values { |labels| labels.sort.join(',').presence }
    end

    def email(user)
      Notify.issues_csv_email(user, project, csv_data, csv_builder.status).deliver_now
    end

    private

    def associations_to_preload
      %i(author assignees timelogs milestone project)
    end

    def header_to_value_hash
      {
       'Issue ID' => 'iid',
       'URL' => -> (issue) { issue_url(issue) },
       'Title' => 'title',
       'State' => -> (issue) { issue.closed? ? 'Closed' : 'Open' },
       'Description' => 'description',
       'Author' => 'author_name',
       'Author Username' => -> (issue) { issue.author&.username },
       'Assignee' => -> (issue) { issue.assignees.map(&:name).join(', ') },
       'Assignee Username' => -> (issue) { issue.assignees.map(&:username).join(', ') },
       'Confidential' => -> (issue) { issue.confidential? ? 'Yes' : 'No' },
       'Locked' => -> (issue) { issue.discussion_locked? ? 'Yes' : 'No' },
       'Due Date' => -> (issue) { issue.due_date&.to_s(:csv) },
       'Created At (UTC)' => -> (issue) { issue.created_at&.to_s(:csv) },
       'Updated At (UTC)' => -> (issue) { issue.updated_at&.to_s(:csv) },
       'Closed At (UTC)' => -> (issue) { issue.closed_at&.to_s(:csv) },
       'Milestone' => -> (issue) { issue.milestone&.title },
       'Weight' => -> (issue) { issue.weight },
       'Labels' => -> (issue) { issue_labels(issue) },
       'Time Estimate' => ->(issue) { issue.time_estimate.to_s(:csv) },
       'Time Spent' => -> (issue) { issue_time_spent(issue) }
      }
    end

    def issue_labels(issue)
      @labels[issue.id]
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def issue_time_spent(issue)
      issue.timelogs.map(&:time_spent).sum
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end

Issues::ExportCsvService.prepend_mod_with('Issues::ExportCsvService')
