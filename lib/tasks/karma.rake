unless Rails.env.production?
  Rake::Task['karma'].clear if Rake::Task.task_defined?('karma')

  namespace :karma do
    desc 'GitLab | Karma | Generate fixtures for JavaScript tests'
    RSpec::Core::RakeTask.new(:fixtures) do |t|
      ENV['NO_KNAPSACK'] = 'true'
      t.pattern = 'spec/javascripts/fixtures/*.rb'
      t.rspec_opts = '--format documentation'
    end

    desc 'GitLab | Karma | Run JavaScript tests'
    task :tests do
      sh "npm run karma" do |ok, res|
        abort('rake karma:tests failed') unless ok
      end
    end
  end

  desc 'GitLab | Karma | Shortcut for karma:fixtures and karma:tests'
  task :karma do
    Rake::Task['karma:fixtures'].invoke
    Rake::Task['karma:tests'].invoke
  end
end
