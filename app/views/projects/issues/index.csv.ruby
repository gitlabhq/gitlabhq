columns = {
  'Issue ID' => 'iid',
  'Title' => 'title',
  'State' => 'state',
  'Description' => 'description',
  'Author' => 'author_name',
  'Assignee' => 'assignee_name',
  'Confidential' => 'confidential',
  'Due Date' => 'due_date',
  'Created At' => 'created_at',
  'Updated At' => 'updated_at',
  'Milestone' => -> (issue) { issue.milestone&.title },
  'Labels' => -> (issue) { issue.label_names.join(',').presence },
}

CSV.generate do |csv|
  csv << columns.keys

  @issues.each do |issue|
    row = columns.values.map do |attribute|
      if attribute.respond_to?(:call)
        attribute.call(issue)
      else
        issue.send(attribute)
      end
    end

    csv << row
  end
end
