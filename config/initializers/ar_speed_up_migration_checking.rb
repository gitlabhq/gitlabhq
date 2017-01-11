if Rails.env.test?
  require 'active_record/migration'

  module ActiveRecord
    class Migrator
      class << self
        alias_method :migrations_unmemoized, :migrations
        alias_method :get_all_versions_unmemoized, :get_all_versions

        # This method is called a large number of times per rspec example, and
        # it reads + parses `db/migrate/*` each time. Memoizing it can save 0.5
        # seconds per spec.
        def migrations(paths)
          @migrations ||= migrations_unmemoized(paths)
        end

        def get_all_versions(connection = Base.connection)
          @all_versions ||= get_all_versions_unmemoized(connection)
        end
      end
    end
  end
end
