# frozen_string_literal: true

require_relative 'database_helper'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseHelper.setup_database

    ActiveRecord::Schema.define do
      create_table :projects do |t|
        t.string :name
      end
    end
  end

  config.after(:suite) do
    DatabaseHelper.teardown_database
  end
end
