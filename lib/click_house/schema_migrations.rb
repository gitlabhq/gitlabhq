# frozen_string_literal: true

module ClickHouse
  module SchemaMigrations
    def self.touch_all(connection, database)
      context = ClickHouse::SchemaMigrations::Context.new(connection, database)

      ClickHouse::SchemaMigrations::Migrations.new(context).touch_all
    end

    def self.load_all(connection, database)
      context = ClickHouse::SchemaMigrations::Context.new(connection, database)

      ClickHouse::SchemaMigrations::Migrations.new(context).load_all
    end
  end
end
