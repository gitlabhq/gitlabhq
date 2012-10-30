MergeRequest.seed(:id, [
  { :id => 1,  milestone_id: 1, project_id: 1, source_branch: 'master', target_branch: 'feature', author_id: 1, assignee_id: 1, title: Faker::Lorem.sentence(6) },
  { :id => 2,  milestone_id: 1, project_id: 1, source_branch: 'master', target_branch: 'feature', author_id: 2, assignee_id: 2, title: Faker::Lorem.sentence(6) },
  { :id => 3,  milestone_id: 1, project_id: 1, source_branch: 'master', target_branch: 'feature', author_id: 3, assignee_id: 3, title: Faker::Lorem.sentence(6) },
  { :id => 4,  milestone_id: 1, project_id: 1, source_branch: 'master', target_branch: 'feature', author_id: 4, assignee_id: 4, title: Faker::Lorem.sentence(6) },
  { :id => 5,  milestone_id: 1, project_id: 1, source_branch: 'master', target_branch: 'feature', author_id: 5, assignee_id: 5, title: Faker::Lorem.sentence(6) },

  { :id => 6,  milestone_id: 5, project_id: 2, source_branch: 'master', target_branch: 'feature', author_id: 1, assignee_id: 1, title: Faker::Lorem.sentence(6) },
  { :id => 7,  milestone_id: 6, project_id: 2, source_branch: 'master', target_branch: 'feature', author_id: 2, assignee_id: 2, title: Faker::Lorem.sentence(6) },
  { :id => 8,  milestone_id: 6, project_id: 2, source_branch: 'master', target_branch: 'feature', author_id: 3, assignee_id: 3, title: Faker::Lorem.sentence(6) },
  { :id => 9,  milestone_id: 6, project_id: 2, source_branch: 'master', target_branch: 'feature', author_id: 4, assignee_id: 4, title: Faker::Lorem.sentence(6) },
  { :id => 11, milestone_id: 5, project_id: 2, source_branch: 'master', target_branch: 'feature', author_id: 5, assignee_id: 5, title: Faker::Lorem.sentence(6) },

  { :id => 12, milestone_id: 9, project_id: 3, source_branch: 'master', target_branch: 'feature', author_id: 1, assignee_id: 1, title: Faker::Lorem.sentence(6)},
  { :id => 13, milestone_id: 9, project_id: 3, source_branch: 'master', target_branch: 'feature', author_id: 2, assignee_id: 2, title: Faker::Lorem.sentence(6)},
  { :id => 14, milestone_id: 9, project_id: 3, source_branch: 'master', target_branch: 'feature', author_id: 3, assignee_id: 3, title: Faker::Lorem.sentence(6)},
  { :id => 15, milestone_id: 9, project_id: 3, source_branch: 'master', target_branch: 'feature', author_id: 4, assignee_id: 4, title: Faker::Lorem.sentence(6)},
  { :id => 16, milestone_id: 9, project_id: 3, source_branch: 'master', target_branch: 'feature', author_id: 5, assignee_id: 5, title: Faker::Lorem.sentence(6)},
])
