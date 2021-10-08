# frozen_string_literal: true

unless Rails.env.production?
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new

  namespace :rubocop do
    namespace :todo do
      desc 'Generate RuboCop todos'
      task :generate do # rubocop:disable Rails/RakeEnvironment
        require 'rubocop'

        options = %w[
          --auto-gen-config
          --auto-gen-only-exclude
          --exclude-limit=100000
          --no-offense-counts
        ]

        RuboCop::CLI.new.run(options)
      end
    end
  end
end
