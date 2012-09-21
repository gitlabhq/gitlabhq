
desc "Imports existing Git repos from a directory into new projects in git_base_path"
task :import_projects, [:directory,:email] => :environment  do |t, args|
  user_email = args.email
  import_directory = args.directory
  repos_to_import = Dir.glob("#{import_directory}/*")
  git_base_path = Gitlab.config.git_base_path
  puts "Found #{repos_to_import.length} repos to import"

  imported_count = 0
  skipped_count = 0
  failed_count = 0
  repos_to_import.each do |repo_path|
    repo_name = File.basename repo_path

    puts "  Processing #{repo_name}"
    clone_path = "#{git_base_path}#{repo_name}.git"

    if Dir.exists? clone_path
      if Project.find_by_code(repo_name)
        puts "  INFO: #{clone_path} already exists in repositories directory, skipping."
        skipped_count += 1
        next
      else
        puts "  INFO: Project doesn't exist for #{repo_name} (but the repo does)."
      end
    else
      # Clone the repo
      unless clone_bare_repo_as_git(repo_path, clone_path)
        failed_count += 1
        next
      end
    end

    # Create the project and repo
    if create_repo_project(repo_name, user_email)
      imported_count += 1
    else
      failed_count += 1
    end

  end

  puts "Finished importing #{imported_count} projects (skipped #{skipped_count}, failed #{failed_count})."
end

# Clones a repo as bare git repo using the git_user
def clone_bare_repo_as_git(existing_path, new_path)
  git_user = Gitlab.config.ssh_user
  begin
    sh "sudo -u #{git_user} -i git clone --bare '#{existing_path}' #{new_path}"
    true
  rescue Exception=> msg
    puts "  ERROR: Faild to clone #{existing_path} to #{new_path}"
	puts "	Make sure #{git_user} can reach #{existing_path}"
	puts "	Exception-MSG: #{msg}"
	false
  end
end

# Creats a project in Gitlag given a @project_name@ to use (for name, web url, and code
# url) and a @user_email@ that will be assigned as the owner of the project.
def create_repo_project(project_name, user_email)
  user = User.find_by_email(user_email)
  if user
    # Using find_by_code since that's the most important identifer to be unique
    if Project.find_by_code(project_name)
      puts "  INFO: Project #{project_name} already exists in Gitlab, skipping."
      false
    else
      project = nil
      if Project.find_by_code(project_name)
        puts "  ERROR: Project already exists #{project_name}"
        return false
        project = Project.find_by_code(project_name)
      else
        project = Project.create(
          name: project_name,
          code: project_name,
          path: project_name,
          owner: user,
          description: "Automatically created from Rake on #{Time.now.to_s}"
        )
      end

      unless project.valid?
        puts "  ERROR: Failed to create project #{project} because #{project.errors.first}"
        return false
      end

      # Add user as admin for project
      project.users_projects.create!(
        :project_access => UsersProject::MASTER,
        :user => user
      )

      # Per projects_controller.rb#37
      project.update_repository

      if project.valid?
        true
      else
        puts "  ERROR: Failed to create project #{project} because #{project.errors.first}"
        false
      end
    end
  else
    puts "  ERROR: #{user_email} not found, skipping"
    false
  end
end
