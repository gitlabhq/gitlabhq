Issue.seed(:id, [
  { :id => 1,  :project_id => 1, :author_id => 1, :assignee_id => 1, :title => Faker::Lorem.sentence(6) },
  { :id => 2,  :project_id => 1, :author_id => 2, :assignee_id => 2, :title => Faker::Lorem.sentence(6) },
  { :id => 3,  :project_id => 1, :author_id => 3, :assignee_id => 3, :title => Faker::Lorem.sentence(6) },
  { :id => 4,  :project_id => 1, :author_id => 4, :assignee_id => 4, :title => Faker::Lorem.sentence(6) },
  { :id => 5,  :project_id => 1, :author_id => 5, :assignee_id => 5, :title => Faker::Lorem.sentence(6) },

  { :id => 6,  :project_id => 2, :author_id => 1, :assignee_id => 1, :title => Faker::Lorem.sentence(6) },
  { :id => 7,  :project_id => 2, :author_id => 2, :assignee_id => 2, :title => Faker::Lorem.sentence(6) },
  { :id => 8,  :project_id => 2, :author_id => 3, :assignee_id => 3, :title => Faker::Lorem.sentence(6) },
  { :id => 9,  :project_id => 2, :author_id => 4, :assignee_id => 4, :title => Faker::Lorem.sentence(6) },
  { :id => 11, :project_id => 2, :author_id => 5, :assignee_id => 5, :title => Faker::Lorem.sentence(6) },

  { :id => 12, :project_id => 3, :author_id => 1, :assignee_id => 1, :title => Faker::Lorem.sentence(6)},
  { :id => 13, :project_id => 3, :author_id => 2, :assignee_id => 2, :title => Faker::Lorem.sentence(6)},
  { :id => 14, :project_id => 3, :author_id => 3, :assignee_id => 3, :title => Faker::Lorem.sentence(6)},
  { :id => 15, :project_id => 3, :author_id => 4, :assignee_id => 4, :title => Faker::Lorem.sentence(6)},
  { :id => 16, :project_id => 3, :author_id => 5, :assignee_id => 5, :title => Faker::Lorem.sentence(6)}
])



