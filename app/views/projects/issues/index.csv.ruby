columns = {
  'Issue ID' => 'iid',
  'Title' => 'title',
  'State' => 'state',
  'Description' => 'description',
  'Author Id' => 'author_id',
  'Assignee Id' => 'assignee_id',
  'Due Date' => 'due_date',
  'Created At' => 'created_at',
  'Updated At' => 'updated_at'
}

CSV.generate do |csv|
  csv << columns.keys

  @issues.pluck(*columns.values).each do |row|
    csv << row
  end
end
