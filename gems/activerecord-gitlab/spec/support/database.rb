# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:all) do
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    ActiveRecord::Base.logger = Logger.new('/dev/null')

    ActiveRecord::Schema.define do
      create_table :projects, force: true do |t|
        t.string :name
      end

      create_table :pipelines, force: true do |t|
        t.integer :project_id
        t.integer :partition_id
      end

      create_table :jobs, force: true do |t|
        t.integer :pipeline_id
        t.integer :partition_id
        t.string :name
      end

      create_table :metadata, force: true do |t|
        t.integer :job_id
        t.integer :partition_id
        t.boolean :test_flag, default: false
      end

      create_table :locking_jobs, force: true do |t|
        t.integer :pipeline_id
        t.integer :partition_id
        t.integer :lock_version, default: 0, null: false
        t.integer :status, default: 0, null: false
        t.string :name
      end
    end
  end
end
