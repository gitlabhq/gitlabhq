Gitlab::Seeder.quiet do

  (1..300).each  do |i|
    # Random Project
    project = Project.scoped.sample

    # Random user
    user = User.not_in_project(project).sample

    next unless user

    UsersProject.seed(:id, [{
      id: i,
      project_id: project.id,
      user_id: user.id,
      project_access: UsersProject.access_roles.values.sample
    }])

    print('.')
  end
end
puts "OK".green
