desc "Imports existing Git repos from a directory into new projects in git_base_path"
task :import_projects, [:directory,:email] => :environment  do |t, args|
  user_email, import_directory = args.email, args.directory
  repos_to_import = Dir.glob("#{import_directory}/*")
  git_base_path = Gitlab.config.git_base_path
  imported_count, skipped_count, failed_count = 0

  puts "Found #{repos_to_import.size} repos to import"

  repos_to_import.each do |repo_path|
    repo_name = File.basename repo_path
    clone_path = "#{git_base_path}#{repo_name}.git"

    puts "  Processing #{repo_name}"

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
  rescue Exception => msg
    puts "  ERROR: Failed to clone #{existing_path} to #{new_path}"
  	puts "	Make sure #{git_user} can reach #{existing_path}"
  	puts "	Exception-MSG: #{msg}"
  end
end

# Creates a project in GitLab given a `project_name` to use
# (for name, web url, and code url) and a `user_email` that will be
# assigned as the owner of the project.
def create_repo_project(project_name, user_email)
  if user = User.find_by_email(user_email)
    # Using find_by_code since that's the most important identifer to be unique
    if Project.find_by_code(project_name)
      puts "  INFO: Project #{project_name} already exists in Gitlab, skipping."
    else
      project = Project.create(
        name: project_name,
        code: project_name,
        path: project_name,
        owner: user,
        description: "Automatically created from 'import_projects' rake task on #{Time.now}"
      )

      if project.valid?
        # Add user as admin for project
        project.users_projects.create!(:project_access => UsersProject::MASTER, :user => user)
        project.update_repository
      else
        puts "  ERROR: Failed to create project #{project} because #{project.errors.first}"
      end
    end
  else
    puts "  ERROR: user with #{user_email} not found, skipping"
  end
end
