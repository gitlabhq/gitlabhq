## run using
## bundle exec rake import_projects[umarshah@simplyphi.com,importdir,namespace] RAILS_ENV=production

desc "Imports existing Git repos into new projects from the import_projects folder"
task :import_projects, [:email,:root,:namespace] => :environment  do |t, args|

  user_email = args.email
  importdir = args.root
  namespace = args.namespace
  gnsp = Namespace.search(namespace).first
  if gnsp.nil?
    puts "Failed to import from #{importdir} , for #{user_email}. Error  namespace: #{namespace} does not exist".red
    next
  end

  imported_count = 0
  skipped_count = 0
  failed_count = 0

  repos_to_import = Dir.glob("#{importdir}/*.git")
  puts "Importing from #{importdir} , for #{user_email} into namespace: #{gnsp.name}".green
  puts "Found #{repos_to_import.length} repos to import".green

  repos_to_import.each do |repo_path|
    repo_name = File.basename repo_path
    repo_full_path = File.absolute_path(repo_path)

    puts "  Processing #{repo_name}".yellow
    git_base_path = Gitlab.config.gitlab_shell.repos_path
    clone_path = "#{git_base_path}/#{gnsp.path}/#{repo_name}".yellow
    repo_name = repo_name.gsub!(/.git$/, '')

    if Dir.exists? clone_path
      if Project.find_with_namespace(repo_name)
        puts "  INFO: #{clone_path} already exists in repositories directory, skipping.".red
        skipped_count += 1
        next
      else
        puts "  INFO: Project doesn't exist for #{repo_name} (but the repo does).".red
      end
    else
      # Clone the repo
      unless clone_bare_repo_as_git(repo_full_path, clone_path)
        failed_count += 1
        next
      end
    end

    # Create the project and repo
    if create_repo_project(repo_name, user_email, gnsp)
      imported_count += 1
    else
      failed_count += 1
    end

  end

  puts "Finished importing #{imported_count} projects (skipped #{skipped_count}, failed #{failed_count}).".green
end

# Clones a repo as bare git repo using the git user
def clone_bare_repo_as_git(existing_path, new_path)
  begin
    sh "git clone --bare '#{existing_path}' #{new_path}"
    true
  rescue
    puts "  ERROR: Faild to clone #{existing_path} to #{new_path}".red
    false
  end
end

# Creats a project in Gitlag given a @project_name@ to use (for name, web url, and code
# url) and a @user_email@ that will be assigned as the owner of the project.
def create_repo_project(project_name, user_email, gnsp)
  user = User.find_by_email(user_email)
  if user
    # Using find_by_code since that's the most important identifer to be unique
    if Project.find_with_namespace(project_name)
      puts "  INFO: Project #{project_name} already exists in Gitlab, skipping.".red
      false
    else
      project = nil
      project_params = {
          :name => project_name,
            :namespace_id  => gnsp.id,
            :issues_tracker => "redmine",
            :issues_tracker_id => project_name,
      }
      project = Projects::CreateContext.new(user, project_params).execute
      if project.valid?
        true
      else
        puts "  ERROR: Failed to create project #{project} because #{project.errors.first}".red
        false
      end
    end
  else
    puts "  ERROR: #{user_email} not found, skipping".red
    false
  end
end

