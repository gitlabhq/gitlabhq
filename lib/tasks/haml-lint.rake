# frozen_string_literal: true

unless Rails.env.production?
  require 'haml_lint/rake_task'

  HamlLint::RakeTask.new
end
