# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaMigrations
      def self.touch_all(connection)
        context = Gitlab::Database::SchemaMigrations::Context.new(connection)

        Gitlab::Database::SchemaMigrations::Migrations.new(context).touch_all
      end

      def self.load_all(connection)
        context = Gitlab::Database::SchemaMigrations::Context.new(connection)

        Gitlab::Database::SchemaMigrations::Migrations.new(context).load_all
      end
    end
  end
end
