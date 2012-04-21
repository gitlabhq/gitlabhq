namespace :gitlab do
  namespace :app do
    desc "GITLAB | Enable auto merge"
    task :enable_automerge => :environment  do
      Gitlabhq::GitHost.system.new.configure do |git|
        git.admin_all_repo
      end

      puts "Done!".green
    end
  end
end
