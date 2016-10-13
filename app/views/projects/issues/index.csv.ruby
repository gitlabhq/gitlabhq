labels = @issues.eager_load(:labels).
                 pluck(:id, 'labels.title').
                 inject(Hash.new([])) do |memo, (issue_id, label)|
                   memo[issue_id] += [label]
                   memo
                 end

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
  'Labels' => -> (issue) { labels[issue.id].sort.join(',').presence }
}

CsvBuilder.new(columns).render(@issues.includes(:author, :assignee))
