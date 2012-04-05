desc "Give gitlab user full access to every repo"
task :gitlab_enable_automerge => :environment  do

  Gitlabhq::GitHost.system.new.configure do |git|
    git.admin_all_repo
  end

  puts "Done!".green
end
