sudo pip install pygments
sudo apt-get install python-dev
sudo gem install bundler
git clone git://github.com/gitlabhq/gitlabhq.git
cd gitlabhq
bundle install --without development test
bundle exec rake db:setup RAILS_ENV=production
bundle exec rake db:seed_fu RAILS_ENV=production
