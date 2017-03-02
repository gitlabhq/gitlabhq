module Issues
  class ExportCsvService
    def initialize(issues_relation)
      @issues = issues_relation
      @labels = @issues.labels_hash
    end

    def csv_data
      csv_builder.render
    end

    def email(user, project)
      Notify.issues_csv_email(user, project, csv_data, @issues.count).deliver_now
    end

    private

    def csv_builder
      @csv_builder ||= CsvBuilder.new(@issues.includes(:author, :assignee),
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
                                     )
    end
  end
end
