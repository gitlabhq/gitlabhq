# frozen_string_literal: true

require_relative 'database_helper'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseHelper.setup_database

    ActiveRecord::Schema.define do
      create_table :projects do |t|
        t.string :name
        t.integer :organization_id
      end

      create_table :issues do |t|
        t.string :title
        t.integer :project_id
        t.integer :namespace_id
      end

      create_table :snippets do |t|
        t.string :content
        t.integer :project_id
        t.integer :organization_id
      end

      create_table :organizations do |t|
        t.string :name
        t.string :status
      end

      create_table :features do |t|
        t.string :key
      end

      create_table :user_details do |t|
        t.string :bio
        t.integer :user_id
      end
    end
  end

  config.after(:suite) do
    DatabaseHelper.teardown_database
  end
end
