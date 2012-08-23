desc "Add all users to all projects, system administratos are added as masters"
task :add_users_to_project_teams => :environment  do |t, args|
  users = User.find_all_by_admin(false, :select => 'id').map(&:id)
  admins = User.find_all_by_admin(true, :select => 'id').map(&:id)

  users.each do |user|
    puts "#{user}"
  end

  Project.all.each do |project|
    puts "Importing #{users.length} users into #{project.path}"
    UsersProject.bulk_import(project, users, UsersProject::DEVELOPER)
    puts "Importing #{admins.length} admins into #{project.path}"
    UsersProject.bulk_import(project, admins, UsersProject::MASTER)
  end
end
