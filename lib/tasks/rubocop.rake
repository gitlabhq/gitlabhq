# frozen_string_literal: true

unless Rails.env.production?
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new

  namespace :rubocop do
    namespace :todo do
      desc 'Generate RuboCop todos'
      task :generate do
        require 'rubocop'

        options = %w[
          --auto-gen-config
          --auto-gen-only-exclude
          --exclude-limit=100000
        ]

        RuboCop::CLI.new.run(options)
      end
    end
  end
end
