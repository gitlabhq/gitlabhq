# frozen_string_literal: true

unless Rails.env.production?
  namespace :frontend do
    desc 'GitLab | Frontend | Generate fixtures for JavaScript tests'
    RSpec::Core::RakeTask.new(:fixtures, [:pattern]) do |t, args|
      require 'fileutils'
      require_relative '../../spec/support/helpers/javascript_fixtures_helpers'

      FileUtils.rm_r(JavaScriptFixturesHelpers.fixture_root_path, force: true)

      directories = %w[spec]
      directories << 'ee/spec' if Gitlab.ee?
      directory_glob = "{#{directories.join(',')}}"
      args.with_defaults(pattern: "#{directory_glob}/frontend/fixtures/**/*.rb")
      ENV['NO_KNAPSACK'] = 'true'
      t.pattern = args[:pattern]
      t.rspec_opts = '--format documentation'
    end

    desc 'GitLab | Frontend | Run JavaScript tests'
    task tests: ['yarn:check'] do
      sh "yarn test" do |ok, res|
        abort('rake frontend:tests failed') unless ok
      end
    end
  end

  desc 'GitLab | Frontend | Shortcut for frontend:fixtures and frontend:tests'
  task frontend: ['frontend:fixtures', 'frontend:tests']
end
