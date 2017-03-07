unless Rails.env.production?
  namespace :karma do
    desc 'GitLab | Karma | Generate fixtures for JavaScript tests'
    RSpec::Core::RakeTask.new(:fixtures) do |t|
      ENV['NO_KNAPSACK'] = 'true'
      t.pattern = 'spec/javascripts/fixtures/*.rb'
      t.rspec_opts = '--format documentation'
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
