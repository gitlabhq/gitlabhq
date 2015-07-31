namespace :gitlab do
  desc "GitLab | Update commit count for projects"
  task update_commit_count: :environment do
    projects = Project.where(commit_count: 0)
    puts "#{projects.size} projects need to be updated. This might take a while."
    ask_to_continue unless ENV['force'] == 'yes'

    projects.find_each(batch_size: 100) do |project|
      print "#{project.name_with_namespace.yellow} ... "

      unless project.repo_exists?
        puts "skipping, because the repo is empty".magenta
        next
      end

      project.update_commit_count
      puts project.commit_count.to_s.green
    end
  end
end
