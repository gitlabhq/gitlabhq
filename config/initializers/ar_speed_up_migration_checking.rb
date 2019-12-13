if Rails.env.test?
  require 'active_record/migration'

  module ActiveRecord
    class Migrator
      class << self
        alias_method :migrations_unmemoized, :migrations

        # This method is called a large number of times per rspec example, and
        # it reads + parses `db/migrate/*` each time. Memoizing it can save 0.5
        # seconds per spec.
        def migrations(paths)
          @migrations ||= {}
          (@migrations[paths] ||= migrations_unmemoized(paths)).dup
        end
      end
    end
  end
end
