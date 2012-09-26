desc "Add all users to all projects (admin users are added as masters)"
task :add_users_to_project_teams => :environment  do |t, args|
  user_ids = User.where(:admin => false).pluck(:id)
  admin_ids = User.where(:admin => true).pluck(:id)

  Project.find_each do |project|
    puts "Importing #{user_ids.size} users into #{project.code}"
    UsersProject.bulk_import(project, user_ids, UsersProject::DEVELOPER)
    puts "Importing #{admin_ids.size} admins into #{project.code}"
    UsersProject.bulk_import(project, admin_ids, UsersProject::MASTER)
  end
end

desc "Add user to as a developer to all projects"
task :add_user_to_project_teams, [:email] => :environment  do |t, args|
  user = User.find_by_email args.email
  project_ids = Project.pluck(:id)

  UsersProject.user_bulk_import(user, project_ids, UsersProject::DEVELOPER)
end
