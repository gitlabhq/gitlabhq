source "https://rubygems.org"

gem 'rails', '4.1.11'

# Specify a sprockets version due to security issue
# See https://groups.google.com/forum/#!topic/rubyonrails-security/doAVp0YaTqY
gem 'sprockets', '~> 2.12.3'

# Default values for AR models
gem "default_value_for", "~> 3.0.0"

# Supported DBs
gem "mysql2", group: :mysql
gem "pg", group: :postgres

# Authentication libraries
gem "devise", '3.2.4'
gem "devise-async", '0.9.0'
gem 'omniauth', "~> 1.2.2"
gem 'omniauth-google-oauth2'
gem 'omniauth-twitter'
gem 'omniauth-github'
gem 'omniauth-shibboleth'
gem 'omniauth-kerberos', group: :kerberos
gem 'omniauth-gitlab'
gem 'omniauth-bitbucket'
gem 'omniauth-saml', '~> 1.4.0'
gem 'doorkeeper', '2.1.3'
gem "rack-oauth2", "~> 1.0.5"

# Two-factor authentication
gem 'devise-two-factor'
gem 'rqrcode-rails3'
gem 'attr_encrypted', '1.3.4'

# Browser detection
gem "browser", '~> 0.8.0'

# Extracting information from a git repository
# Provide access to Gitlab::Git library
gem "gitlab_git", '~> 7.2.14'

# Ruby/Rack Git Smart-HTTP Server Handler
# GitLab fork with a lot of changes (improved thread-safety, better memory usage etc)
# For full list of changes see https://github.com/SaitoWu/grack/compare/master...gitlabhq:master
gem 'gitlab-grack', '~> 2.0.2', require: 'grack'

# LDAP Auth
# GitLab fork with several improvements to original library. For full list of changes
# see https://github.com/intridea/omniauth-ldap/compare/master...gitlabhq:master
gem 'gitlab_omniauth-ldap', '1.2.1', require: "omniauth-ldap"

# Git Wiki
gem 'gollum-lib', '~> 4.0.2'

# Language detection
# GitLab fork of linguist does not require pygments/python dependency.
# New version of original gem also dropped pygments support but it has strict
# dependency to unstable rugged version. We have internal issue for replacing
# fork with original gem when we meet on same rugged version - https://dev.gitlab.org/gitlab/gitlabhq/issues/2052.
gem "gitlab-linguist", "~> 3.0.1", require: "linguist"

# API
gem "grape", "~> 0.6.1"
gem "grape-entity", "~> 0.4.2"
gem 'rack-cors', require: 'rack/cors'

# Format dates and times
# based on human-friendly examples
gem "stamp"

# Enumeration fields
gem 'enumerize'

# Pagination
gem "kaminari", "~> 0.15.1"

# HAML
gem "haml-rails"

# Files attachments
gem "carrierwave"

# Drag and Drop UI
gem 'dropzonejs-rails'

# for aws storage
gem "fog", "~> 1.25.0"
gem "unf"

# Authorization
gem "six"

# Seed data
gem "seed-fu"

# Markdown and HTML processing
gem 'html-pipeline', '~> 1.11.0'
gem 'task_list',     '1.0.2', require: 'task_list/railtie'
gem 'github-markup'
gem 'redcarpet',     '~> 3.3.2'
gem 'RedCloth'
gem 'rdoc',          '~>3.6'
gem 'org-ruby',      '= 0.9.12'
gem 'creole',        '~>0.3.6'
gem 'wikicloth',     '=0.8.1'
gem 'asciidoctor',   '~> 1.5.2'

# Diffs
gem 'diffy', '~> 3.0.3'

# Application server
group :unicorn do
  gem "unicorn", '~> 4.6.3'
  gem 'unicorn-worker-killer'
end

# State machine
gem "state_machine"

# Issue tags
gem 'acts-as-taggable-on', '~> 3.4'

# Background jobs
gem 'slim'
gem 'sinatra', require: nil
gem 'sidekiq', '~> 3.3'
gem 'sidetiq', '0.6.3'

# HTTP requests
gem "httparty"

# Colored output to console
gem "colored"

# GitLab settings
gem 'settingslogic'

# Misc
gem "foreman"
gem 'version_sorter'

# Cache
gem "redis-rails"

# Campfire integration
gem 'tinder', '~> 1.9.2'

# HipChat integration
gem 'hipchat', '~> 1.5.0'

# Flowdock integration
gem "gitlab-flowdock-git-hook", "~> 1.0.1"

# Gemnasium integration
gem "gemnasium-gitlab-service", "~> 0.2"

# Slack integration
gem "slack-notifier", "~> 1.0.0"

# Asana integration
gem 'asana', '~> 0.0.6'

# d3
gem 'd3_rails', '~> 3.5.5'

#cal-heatmap
gem "cal-heatmap-rails", "~> 0.0.1"

# underscore-rails
gem "underscore-rails", "~> 1.4.4"

# Sanitize user input
gem "sanitize", '~> 2.0'

# Protect against bruteforcing
gem "rack-attack", '~> 4.3.0'

# Ace editor
gem 'ace-rails-ap'

# Keyboard shortcuts
gem 'mousetrap-rails'

# Detect and convert string character encoding
gem 'charlock_holmes'

gem "sass-rails", '~> 4.0.5'
gem "coffee-rails"
gem "uglifier"
gem 'turbolinks', '~> 2.5.0'
gem 'jquery-turbolinks'

gem 'addressable'
gem 'bootstrap-sass',     '~> 3.0'
gem 'font-awesome-rails', '~> 4.2'
gem 'gitlab_emoji',       '~> 0.1'
gem 'gon',                '~> 5.0.0'
gem 'jquery-atwho-rails', '~> 1.0.0'
gem 'jquery-rails',       '3.1.3'
gem 'jquery-scrollto-rails'
gem 'jquery-ui-rails'
gem 'nprogress-rails'
gem 'raphael-rails',      '~> 2.1.2'
gem 'request_store'
gem 'select2-rails',      '~> 3.5.9'
gem 'virtus'

group :development do
  gem 'brakeman', require: false
  gem "annotate", "~> 2.6.0.beta2"
  gem "letter_opener"
  gem 'quiet_assets', '~> 1.0.1'
  gem 'rack-mini-profiler', require: false
  gem 'rerun', '~> 0.10.0'

  # Better errors handler
  gem 'better_errors'
  gem 'binding_of_caller'

  # Docs generator
  gem "sdoc"

  # thin instead webrick
  gem 'thin'
end

group :development, :test do
  gem 'awesome_print'
  gem 'byebug', platform: :mri
  gem 'fuubar', '~> 2.0.0'
  gem 'pry-rails'

  gem 'coveralls',        '~> 0.8.2', require: false
  gem 'database_cleaner', '~> 1.4.0'
  gem 'factory_girl_rails'
  gem 'rspec-rails',      '~> 3.3.0'
  gem 'rubocop',          '0.28.0',   require: false
  gem 'spinach-rails'

  # Prevent occasions where minitest is not bundled in packaged versions of ruby (see #3826)
  gem 'minitest', '~> 5.3.0'

  # Generate Fake data
  gem 'ffaker', '~> 2.0.0'

  gem 'capybara',            '~> 2.4.0'
  gem 'capybara-screenshot', '~> 1.0.0'
  gem 'poltergeist',         '~> 1.6.0'

  gem 'teaspoon', '~> 1.0.0'
  gem 'teaspoon-jasmine'

  gem 'spring', '~> 1.3.1'
  gem 'spring-commands-rspec',    '~> 1.0.0'
  gem 'spring-commands-spinach',  '~> 1.0.0'
  gem 'spring-commands-teaspoon', '~> 0.0.2'
end

group :test do
  gem 'simplecov', require: false
  gem 'shoulda-matchers', '~> 2.8.0', require: false
  gem 'email_spec', '~> 1.6.0'
  gem 'webmock', '~> 1.21.0'
  gem 'test_after_commit'
end

group :production do
  gem "gitlab_meta", '7.0'
end

gem "newrelic_rpm"

gem 'octokit', '3.7.0'
