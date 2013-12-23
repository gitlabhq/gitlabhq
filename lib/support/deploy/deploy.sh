# This is deploy script we use to update staging server
# You can always modify it for your needs :)

# If any command return non-zero status - stop deploy
set -e

echo 'Deploy: Stoping sidekiq..'
cd /home/git/gitlab/ && sudo -u git -H bundle exec rake sidekiq:stop RAILS_ENV=production

echo 'Deploy: Show deploy index page'
sudo -u git -H cp /home/git/gitlab/public/deploy.html /home/git/gitlab/public/index.html

echo 'Deploy: Starting backup...'
cd /home/git/gitlab/ && sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production

echo 'Deploy: Stop GitLab server'
sudo service gitlab stop

echo 'Deploy: Get latest code'
cd /home/git/gitlab/

# clean working directory
sudo -u git -H git stash 

# change branch to 
sudo -u git -H git pull origin master

echo 'Deploy: Bundle and migrate'

# change it to your needs
sudo -u git -H bundle --without aws development test postgres --deployment

sudo -u git -H bundle exec rake db:migrate RAILS_ENV=production
sudo -u git -H bundle exec rake assets:clean RAILS_ENV=production
sudo -u git -H bundle exec rake assets:precompile RAILS_ENV=production
sudo -u git -H bundle exec rake cache:clear RAILS_ENV=production

# return stashed changes (if necessary)
# sudo -u git -H git stash pop

echo 'Deploy: Starting GitLab server...'
sudo service gitlab start

sudo -u git -H rm /home/git/gitlab/public/index.html
echo 'Deploy: Done'