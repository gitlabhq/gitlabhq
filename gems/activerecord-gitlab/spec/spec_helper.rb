# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "active_record/gitlab_patches"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  Dir[File.expand_path("spec/support/**/*.rb")].each { |f| require f }

  config.around(:all, :partitioning) do |example|
    ActiveRecord::Base.transaction do
      example.run

      raise ActiveRecord::Rollback
    end
  end

  config.before(:all, :without_sqlite3) do
    ActiveRecord::Base.remove_connection
  end
end
