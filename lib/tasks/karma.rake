unless Rails.env.production?
  namespace :karma do
    desc 'GitLab | Karma | Generate fixtures for JavaScript tests'
    task fixtures: ['karma:copy_emojis_from_public_folder', 'karma:rspec_fixtures']

    desc 'GitLab | Karma | Generate fixtures using RSpec'
    RSpec::Core::RakeTask.new(:rspec_fixtures, [:pattern]) do |t, args|
      args.with_defaults(pattern: '{spec,ee/spec}/javascripts/fixtures/*.rb')
      ENV['NO_KNAPSACK'] = 'true'
      t.pattern = args[:pattern]
      t.rspec_opts = '--format documentation'
    end

    desc 'GitLab | Karma | Copy emojis file'
    task :copy_emojis_from_public_folder do
      # Copying the emojis.json from the public folder
      fixture_file_name = Rails.root.join('spec/javascripts/fixtures/emojis/emojis.json')
      FileUtils.mkdir_p(File.dirname(fixture_file_name))
      FileUtils.cp(Rails.root.join('public/-/emojis/1/emojis.json'), fixture_file_name)
    end

    desc 'GitLab | Karma | Run JavaScript tests'
    task tests: ['yarn:check'] do
      sh "yarn run karma" do |ok, res|
        abort('rake karma:tests failed') unless ok
      end
    end
  end

  desc 'GitLab | Karma | Shortcut for karma:fixtures and karma:tests'
  task karma: ['karma:fixtures', 'karma:tests']
end
