columns = {
  'Issue ID' => 'iid',
  'Title' => 'title',
  'State' => 'state',
  'Description' => 'description',
  'Author' => 'author_name',
  'Assignee' => 'assignee_name',
  'Confidential' => 'confidential',
  'Due Date' => -> (issue) { issue.due_date&.strftime('%Y-%m-%d') },
  'Created At (UTC)' => -> (issue) { issue.created_at&.strftime('%Y-%m-%d %H:%M:%S') },
  'Updated At (UTC)' => -> (issue) { issue.updated_at&.strftime('%Y-%m-%d %H:%M:%S') },
  'Milestone' => -> (issue) { issue.milestone&.title },
  'Labels' => -> (issue) { issue.labels_array.sort_by(&:title).map(&:title).join(',').presence },
}

CsvBuilder.new(columns).render(@issues.includes(:author, :assignee, :labels))
