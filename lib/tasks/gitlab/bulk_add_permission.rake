namespace :gitlab do
  namespace :import do
    desc "GITLAB | Add all users to all projects (admin users are added as masters)"
    task :all_users_to_all_projects => :environment  do |t, args|
      user_ids = User.where(:admin => false).pluck(:id)
      admin_ids = User.where(:admin => true).pluck(:id)

      Project.find_each do |project|
        puts "Importing #{user_ids.size} users into #{project.code}"
        UsersProject.bulk_import(project, user_ids, UsersProject::DEVELOPER)
        puts "Importing #{admin_ids.size} admins into #{project.code}"
        UsersProject.bulk_import(project, admin_ids, UsersProject::MASTER)
      end
    end

    desc "GITLAB | Add a specific user to all projects (as a developer)"
    task :user_to_projects, [:email] => :environment  do |t, args|
      user = User.find_by_email args.email
      project_ids = Project.pluck(:id)

      UsersProject.user_bulk_import(user, project_ids, UsersProject::DEVELOPER)
    end
  end
end