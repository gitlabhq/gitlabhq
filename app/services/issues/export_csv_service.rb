module Issues
  class ExportCsvService
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
      Notify.issues_csv_email(user, project, csv_data, @issues.count, csv_builder.truncated?).deliver_now
    end

    def csv_builder
      @csv_builder ||=
        CsvBuilder.new(@issues.includes(:author, :assignee), header_to_value_hash)
    end

    private

    def header_to_value_hash
      {
       'Issue ID' => 'iid',
       'Title' => 'title',
       'State' => 'state',
       'Description' => 'description',
       'Author' => 'author_name',
       'Assignee' => 'assignee_name',
       'Confidential' => 'confidential',
       'Due Date' => -> (issue) { issue.due_date&.to_s(:csv) },
       'Created At (UTC)' => -> (issue) { issue.created_at&.to_s(:csv) },
       'Updated At (UTC)' => -> (issue) { issue.updated_at&.to_s(:csv) },
       'Milestone' => -> (issue) { issue.milestone&.title },
       'Labels' => -> (issue) { @labels[issue.id].sort.join(',').presence }
      }
    end
  end
end
