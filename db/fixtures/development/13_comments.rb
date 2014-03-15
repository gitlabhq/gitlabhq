ActiveRecord::Base.observers.disable :all

Issue.all.limit(10).each_with_index do |issue, i|
  5.times do
    Note.seed(:id, [{
      project_id: issue.project.id,
      author_id: issue.project.team.users.sample.id,
      note: Faker::Lorem.sentence,
      noteable_id: issue.id,
      noteable_type: 'Issue'
    }])
  end
end
