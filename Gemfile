source "http://rubygems.org"

gem "rails", "3.2.5"

# Supported DBs
gem "sqlite3"
gem "mysql2"

# Auth
gem "devise", "~> 2.1.0"

# GITLAB patched libs
gem "grit",          :git => "https://github.com/gitlabhq/grit.git",            :ref => "7f35cb98ff17d534a07e3ce6ec3d580f67402837"
gem "gitolite",      :git => "https://github.com/gitlabhq/gitolite-client.git", :ref => "9b715ca8bab6529f6c92204a25f84d12f25a6eb0"
gem "pygments.rb",   :git => "https://github.com/gitlabhq/pygments.rb.git",     :ref => "2cada028da5054616634a1d9ca6941b65b3ce188"
gem "omniauth-ldap", :git => "https://github.com/gitlabhq/omniauth-ldap.git",   :ref => "7edf27d0281e09561838122982c16b7e62181f44"
gem 'yaml_db',       :git => "https://github.com/gitlabhq/yaml_db.git"
gem 'grack',         :git => "https://github.com/gitlabhq/grack.git"
gem "linguist", "~> 1.0.0", :git => "https://github.com/gitlabhq/linguist.git"

gem "grape"
gem "stamp"
gem "kaminari"
gem "haml-rails"
gem "carrierwave"
gem "six"
gem "ffaker"
gem "seed-fu"
gem "redcarpet", "~> 2.1.1"
gem "thin"
gem "unicorn"
gem "git"
gem "acts_as_list"
gem "acts-as-taggable-on", "2.3.1"
gem "drapper"
gem "resque", "~> 1.20.0"
gem "httparty"
gem "charlock_holmes"
gem "foreman"
gem "colored"
gem 'resque_mailer'
gem 'tabs_on_rails'
gem 'settingslogic'

group :assets do
  gem "sass-rails",   "3.2.5"
  gem "coffee-rails", "3.2.2"
  gem "uglifier",     "1.0.3"
  gem "therubyracer"

  gem 'chosen-rails'
  gem "jquery-rails",     "2.0.2"
  gem "jquery-ui-rails",  "0.5.0"
  gem "modernizr",        "2.5.3"
  gem "raphael-rails",    "1.5.2"
  gem 'bootstrap-sass',   "2.0.3.1"
end

group :development do
  gem "letter_opener"
  gem "rails-footnotes"
  gem "annotate", :git => "https://github.com/ctran/annotate_models.git"
end

group :development, :test do
  gem "rspec-rails"
  gem "capybara"
  gem "autotest"
  gem "autotest-rails"
  gem "pry"
  gem "awesome_print"
  gem "database_cleaner"
  gem "launchy"
  gem "webmock"
end

group :test do
  gem 'cucumber-rails', :require => false
  gem 'minitest', ">= 2.10"
  gem "turn", :require => false
  gem "simplecov", :require => false
  gem "shoulda-matchers"
  gem 'email_spec'
  gem 'resque_spec'
end
