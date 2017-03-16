module RenameableColumn
  extend ActiveSupport::Concern

  module ClassMethods
    def rename_column(old_column, new_column, migrations:)
      unless migration_exists?(migrations[:add_new])
        raise "Cannot find migration '#{migrations[:add_new]}'"
      end

      unless migration_exists?(migrations[:migrate_data])
        raise "Cannot find migration '#{migrations[:migrate_data]}'"
      end

      unless migration_exists?(migrations[:remove_old])
        raise "Cannot find migration '#{migrations[:remove_old]}'"
      end

      if migration_ran?(migrations[:remove_old])
        old_column_removed(old_column, new_column)
      elsif migration_ran?(migrations[:migrate_data])
        data_migrated_from_old_to_new_column(old_column, new_column)
      elsif migration_ran?(migrations[:add_new])
        new_column_added(old_column, new_column)
      end
    end

    private

    def new_column_added(old_column, new_column)
      log_column_rename_status(old_column, new_column)
      Rails.logger.info "The `#{new_column}` column has been added, but the data has not yet been migrated, and the `#{old_column}` column has not yet been removed."
      log_column_usage_instructions(old_column, new_column)

      before_save do
        self[new_column] = self[old_column]

        true
      end

      define_method "#{new_column}=" do |new_value|
        raise "Use `#{self.class.name}##{old_column}=` until data is migrated from `#{old_column}` to `#{new_column}`"
      end

      define_singleton_method column_name_method(new_column) do
        old_column
      end
    end

    def data_migrated_from_old_to_new_column(old_column, new_column)
      log_column_rename_status(old_column, new_column)
      Rails.logger.info "The `#{new_column}` column has been added and the data has been migrated, but the `#{old_column}` column has not yet been removed."
      log_column_usage_instructions(old_column, new_column)

      # We read and write to and from `new_column`, but the code still says `old_column`
      include IgnorableColumn

      ignore_column old_column

      alias_attribute old_column, new_column

      define_singleton_method column_name_method(new_column) do
        new_column
      end
    end

    def old_column_removed(old_column, new_column)
      warn "WARNING: `#{self.name}` column `#{old_column}` has been renamed to `#{new_column}`."
      warn "All code should be updated to use `#{new_column}` where `#{old_column}` or the value of `#{self.name}.#{column_name_method(new_column)}` is currently used, and `rename_column #{old_column.inspect}, #{new_column.inspect}` should be removed from `#{self.name}`."

      alias_attribute old_column, new_column

      define_singleton_method column_name_method(new_column) do
        new_column
      end
    end

    def log_column_rename_status(old_column, new_column)
      Rails.logger.info "`#{self.name}` column `#{old_column}` is in the process of being renamed to `#{new_column}`."
    end

    def log_column_usage_instructions(old_column, new_column)
      Rails.logger.info "Until the rename is complete, all code should continue to read and write from `#{old_column}`, which may be the actual attribute or an ActiveRecord alias. However, plain SQL and Arel queries should use `#{self.name}.#{column_name_method(new_column)}`, which will return `#{old_column.inspect}` or `#{new_column.inspect}` based on the current state of the database."
    end

    def column_name_method(new_column)
      "#{new_column}_column_name"
    end

    def all_migrations
      @all_migrations ||= Set.new(ActiveRecord::Migrator.migrations(['db/release_migrations']).map(&:version))
    end

    def migration_exists?(name)
      version = name.match(/^([0-9]+)/)[1].to_i
      all_migrations.include?(version)
    end

    def ran_migrations
      @ran_migrations ||= Set.new(ActiveRecord::Migrator.get_all_versions)
    end

    def migration_ran?(name)
      version = name.match(/^([0-9]+)/)[1].to_i
      ran_migrations.include?(version)
    end
  end
end
