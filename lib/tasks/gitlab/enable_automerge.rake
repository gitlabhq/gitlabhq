namespace :gitlab do
  namespace :app do
    desc "GITLAB | Enable auto merge"
    task :enable_automerge => :environment do
      Gitlab::Gitolite.new.enable_automerge

      Project.find_each do |project|
        if project.repo_exists? && !project.satellite.exists?
          puts "Creating satellite for #{project.name}...".green
          project.satellite.create
        end
      end

      puts "Done!".green
    end
  end
end
