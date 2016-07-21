module Gitlab
  # Checks if a set of migrations requires downtime or not.
  class DowntimeCheck
    # The constant containing the boolean that indicates if downtime is needed
    # or not.
    DOWNTIME_CONST = :DOWNTIME

    # The constant that specifies the reason for the migration requiring
    # downtime.
    DOWNTIME_REASON_CONST = :DOWNTIME_REASON

    # Checks the given migration paths and returns an Array of
    # `Gitlab::DowntimeCheck::Message` instances.
    #
    # migrations - The migration file paths to check.
    def check(migrations)
      migrations.map do |path|
        require(path)

        migration_class = class_for_migration_file(path)

        unless migration_class.const_defined?(DOWNTIME_CONST)
          raise "The migration in #{path} does not specify if it requires " \
            "downtime or not"
        end

        if online?(migration_class)
          Message.new(path)
        else
          reason = downtime_reason(migration_class)

          unless reason
            raise "The migration in #{path} requires downtime but no reason " \
              "was given"
          end

          Message.new(path, true, reason)
        end
      end
    end

    # Checks the given migrations and prints the results to STDOUT/STDERR.
    #
    # migrations - The migration file paths to check.
    def check_and_print(migrations)
      check(migrations).each do |message|
        puts message.to_s # rubocop: disable Rails/Output
      end
    end

    # Returns the class for the given migration file path.
    def class_for_migration_file(path)
      File.basename(path, File.extname(path)).split('_', 2).last.camelize.
        constantize
    end

    # Returns true if the given migration can be performed without downtime.
    def online?(migration)
      migration.const_get(DOWNTIME_CONST) == false
    end

    # Returns the downtime reason, or nil if none was defined.
    def downtime_reason(migration)
      if migration.const_defined?(DOWNTIME_REASON_CONST)
        migration.const_get(DOWNTIME_REASON_CONST)
      else
        nil
      end
    end
  end
end
