namespace :gitlab do
  namespace :app do
    desc "GITLAB | Fix post receive"
    task :fix_post_receive => :environment do
      Gitlab::GitHost.system.new.configure do |c|
        c.update_projects(Project.all)
      end
      puts "Done!".green
    end
  end
end
