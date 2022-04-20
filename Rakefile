#!/usr/bin/env rake
# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

Rake::TaskManager.record_task_metadata = true

require File.expand_path('config/application', __dir__)

relative_url_conf = File.expand_path('config/initializers/relative_url', __dir__)
require relative_url_conf if File.exist?("#{relative_url_conf}.rb")

require File.expand_path('config/initializers/01_active_record_database_tasks_configuration_flag.rb', __dir__)

Gitlab::Application.load_tasks

Knapsack.load_tasks if defined?(Knapsack)

require 'gitlab-dangerfiles'
Gitlab::Dangerfiles.load_tasks
