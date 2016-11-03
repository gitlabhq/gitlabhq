unless Rails.env.production?
  Rake::Task['teaspoon'].clear if Rake::Task.task_defined?('teaspoon')

  namespace :teaspoon do
    desc 'GitLab | Teaspoon | Generate fixtures for JavaScript tests'
    RSpec::Core::RakeTask.new(:fixtures) do |t|
      ENV['NO_KNAPSACK'] = 'true'
      t.pattern = 'spec/javascripts/fixtures/*.rb'
      t.rspec_opts = '--format documentation'
    end

    desc 'GitLab | Teaspoon | Run JavaScript tests'
    task :tests do
      require "teaspoon/console"
      options = {}
      abort('rake teaspoon:tests failed') if Teaspoon::Console.new(options).failures?
    end
  end

  desc 'GitLab | Teaspoon | Shortcut for teaspoon:fixtures and teaspoon:tests'
  task :teaspoon do
    Rake::Task['teaspoon:fixtures'].invoke
    Rake::Task['teaspoon:tests'].invoke
  end
end
