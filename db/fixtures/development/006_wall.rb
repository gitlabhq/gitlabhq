Gitlab::Seeder.quiet do
  (1..300).each  do |i|
    # Random Project
    project_id = rand(2) + 1
    project = Project.find(project_id)

    # Random user
    user = project.users.sample
    user_id = user.id

    Note.seed(:id, [{
      id: i,
      project_id: project_id,
      author_id: user_id,
      note: Faker::Lorem.sentence(6)
    }])
    print('.')
  end
end
