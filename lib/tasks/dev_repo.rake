desc "Prepare for development"
task :dev_repo => :environment  do
key = `sudo -u gitlabdev -H cat /home/gitlabdev/.ssh/id_rsa.pub`
raise "\n *** Run ./lib/tasks/dev_user.sh first *** \n" if key.empty?
Key.create(:user_id => User.first, :key => key, :title => "gitlabdev")

puts "\n *** Clone diaspora from github"
`sudo -u gitlabdev -H sh -c "cd /home/gitlabdev; git clone git://github.com/diaspora/diaspora.git /home/gitlabdev/diaspora"`

puts "\n *** Push diaspora source to gitlab"
`sudo -u gitlabdev -H sh -c "cd /home/gitlabdev/diaspora; git remote add local git@localhost:diaspora.git; git push local master; git push local --tags; git checkout -b api origin/api; git push local api; git checkout -b heroku origin/heroku; git push local heroku"`

puts "\n *** Clone rails from github"
`sudo -u gitlabdev -H sh -c "cd /home/gitlabdev; git clone git://github.com/rails/rails.git /home/gitlabdev/rails"`

puts "\n *** Push rails source to gitlab"
`sudo -u gitlabdev -H sh -c "cd /home/gitlabdev/rails; git remote add local git@localhost:ruby_on_rails.git; git push local master; git push local --tags"`

puts "\n *** Clone rubinius from github"
`sudo -u gitlabdev -H sh -c "cd /home/gitlabdev; git clone git://github.com/rubinius/rubinius.git /home/gitlabdev/rubinius"`

puts "\n *** Push rubinius source to gitlab"
`sudo -u gitlabdev -H sh -c "cd /home/gitlabdev/rubinius; git remote add local git@localhost:rubinius.git; git push local master; git push local --tags"`
end
