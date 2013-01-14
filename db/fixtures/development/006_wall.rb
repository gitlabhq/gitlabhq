Gitlab::Seeder.quiet do
  (1..300).each  do |i|
    # Random Project
    project = Project.all.sample

    # Random user
    user = project.users.sample

    next unless user

    user_id = user.id

    Note.seed(:id, [{
      id: i,
      project_id: project.id,
      author_id: user_id,
      note: Faker::Lorem.sentence(6)
    }])
    print('.')
  end
end
