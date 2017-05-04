desc "Cleanup repositories for all projects"
task :cleanup_repositories => :environment  do |t, args|
  cleaned_count, failed_count = 0, 0

  Project.all.each do |project|
    if cleanup_repository_for_project(project)
      cleaned_count += 1
    else
      failed_count += 1
    end
  end

  puts "Finished cleaning #{cleaned_count} repositories (failed #{failed_count})."
end

def cleanup_repository_for_project(project)
  git_user = Gitlab.config.ssh_user
  git_command = "git gc"
  begin
    sh "sudo -u #{git_user} -i cd #{project.path_to_repo} && #{git_command}"
    true
  rescue Exception => msg
    puts "  ERROR: Failed to #{git_command} @ #{project.path} as #{git_user} user"
    puts "	Exception-MSG: #{msg}"
    false
  end
end
