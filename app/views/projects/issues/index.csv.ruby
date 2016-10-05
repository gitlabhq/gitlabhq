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

CsvBuilder.new(columns).render(@issues)
