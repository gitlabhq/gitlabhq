module Issues
  class ExportCsvService
    include Gitlab::Routing.url_helpers
    include GitlabRoutingHelper

    # Target attachment size before base64 encoding
    TARGET_FILESIZE = 15000000

    def initialize(issues_relation)
      @issues = issues_relation
      @labels = @issues.labels_hash
    end

    def csv_data
      csv_builder.render(TARGET_FILESIZE)
    end

    def email(user, project)
      Notify.issues_csv_email(user, project, csv_data, csv_builder.status).deliver_now
    end

    def csv_builder
      @csv_builder ||=
        CsvBuilder.new(@issues.preload(:author, :assignees, :timelogs), header_to_value_hash)
    end

    private

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
       'Due Date' => -> (issue) { issue.due_date&.to_s(:csv) },
       'Created At (UTC)' => -> (issue) { issue.created_at&.to_s(:csv) },
       'Updated At (UTC)' => -> (issue) { issue.updated_at&.to_s(:csv) },
       'Closed At (UTC)' => -> (issue) { issue.closed_at&.to_s(:csv) },
       'Milestone' => -> (issue) { issue.milestone&.title },
       'Weight' => -> (issue) { issue.weight },
       'Labels' => -> (issue) { @labels[issue.id].sort.join(',').presence },
       'Time Estimate' => ->(issue) { issue.time_estimate.to_s(:csv) },
       'Time Spent' => -> (issue) { issue.timelogs.map(&:time_spent).inject(0, :+)}
      }
    end
  end
end
