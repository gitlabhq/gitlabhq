# frozen_string_literal: true

unless Rails.env.production?
  require 'haml_lint/rake_task'
  require Rails.root.join('haml_lint/inline_javascript')

  HamlLint::RakeTask.new
end
