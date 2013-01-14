UsersProject.skip_callback(:save, :after, :update_repository)

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

UsersProject.set_callback(:save, :after, :update_repository)

puts "\nRebuild gitolite\n".yellow
Project.all.each(&:update_repository)
puts "OK".green
