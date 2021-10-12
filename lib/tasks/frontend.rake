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

    desc 'GitLab | Frontend | Generate fixtures for JavaScript integration tests'
    RSpec::Core::RakeTask.new(:mock_server_rspec_fixtures) do |t, args|
      require 'yaml'

      base_path = Pathname.new('spec/frontend_integration/fixture_generators.yml')
      ee_path = Pathname.new('ee') + base_path

      fixtures = YAML.safe_load(base_path.read)
      fixtures.concat(Array(YAML.safe_load(ee_path.read))) if Gitlab.ee? && ee_path.exist?

      t.pattern = fixtures.join(',')
      ENV['NO_KNAPSACK'] = 'true'
      t.rspec_opts = '--format documentation'
    end

    desc 'GitLab | Frontend | Run JavaScript tests'
    task tests: ['yarn:check'] do
      sh "yarn test" do |ok, res|
        abort('rake frontend:tests failed') unless ok
      end
    end

    desc 'GitLab | Frontend | Shortcut for generating all fixtures used by MirajeJS mock server'
    task mock_server_fixtures: ['frontend:mock_server_rspec_fixtures', 'gitlab:graphql:schema:dump']
  end

  desc 'GitLab | Frontend | Shortcut for frontend:fixtures and frontend:tests'
  task frontend: ['frontend:fixtures', 'frontend:tests']
end
