# frozen_string_literal: true

unless Rails.env.production?
  namespace :karma do
    # alias exists for legacy reasons
    desc 'GitLab | Karma | Generate fixtures for JavaScript tests'
    task fixtures: ['frontend:fixtures']

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
