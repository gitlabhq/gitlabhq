source "http://rubygems.org"

gem "rails", "3.1.1"

gem "sqlite3"
gem "rake", "0.9.2.2"
gem "devise", "1.5.0"
gem "stamp"
gem "kaminari"
gem "haml", "3.1.4"
gem "haml-rails"
gem "jquery-rails"
gem "grit", :git => "https://github.com/gitlabhq/grit.git"
gem "gitolite", :git => "https://github.com/gitlabhq/gitolite-client.git"
gem "carrierwave"
gem "six"
gem "therubyracer"
gem "faker"
gem "seed-fu", "~> 2.1.0"
gem "pygments.rb", "0.2.4"
gem "thin"
gem "git"
gem "acts_as_list"
gem "rdiscount"
gem "acts-as-taggable-on", "~> 2.1.0"
gem "drapper"
gem "resque"
gem "httparty"
gem "charlock_holmes"
gem "foreman"

group :assets do
  gem "sass-rails",   "~> 3.1.0"
  gem "coffee-rails", "~> 3.1.0"
  gem "uglifier"
end

group :development do
  gem "letter_opener"
  gem "rails-footnotes", "~> 3.7.5"
  gem "annotate", :git => "https://github.com/ctran/annotate_models.git"
end

group :development, :test do
  gem "rspec-rails"
  gem "capybara"
  gem "autotest"
  gem "autotest-rails"
  unless ENV["CI"]
    gem "ruby-debug19", :require => "ruby-debug"
  end
  gem "awesome_print"
  gem "database_cleaner"
  gem "launchy"
  gem "webmock"
end

group :production do
  gem "mysql2"
end

group :test do
  gem "turn", :require => false
  gem "simplecov", :require => false
  gem "shoulda", "~> 3.0.0.beta2"
end
