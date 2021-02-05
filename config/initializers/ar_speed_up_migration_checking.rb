# frozen_string_literal: true

if Rails.env.test?
  require 'active_record/migration'

  module ActiveRecord
    class MigrationContext
      alias_method :migrations_unmemoized, :migrations

      # This method is called a large number of times per rspec example, and
      # it reads + parses `db/migrate/*` each time. Memoizing it can save 0.5
      # seconds per spec.
      def migrations
        @migrations ||= migrations_unmemoized
      end
    end
  end
end
