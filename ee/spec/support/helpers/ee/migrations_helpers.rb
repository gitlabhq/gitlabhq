module EE
  module MigrationsHelpers
    extend ::Gitlab::Utils::Override

    override :reset_column_information
    def reset_column_information(klass)
      super
    rescue Geo::TrackingBase::SecondaryNotConfigured
    end

    override :active_record_base
    def active_record_base
      if geo_migration?
        Geo::TrackingBase
      else
        super
      end
    end

    override :migrations_paths
    def migrations_paths
      if geo_migration?
        ::Gitlab::Geo::DatabaseTasks.geo_migrate_path
      else
        super
      end
    end

    override :schema_migrate_down!
    def schema_migrate_down!
      with_db_config { super }
    end

    override :schema_migrate_up!
    def schema_migrate_up!
      with_db_config { super }
    end

    override :migrate!
    def migrate!
      with_db_config { super }
    end

    def with_db_config(&block)
      if geo_migration?
        ::Gitlab::Geo::DatabaseTasks.with_geo_db { yield }
      else
        yield
      end
    end

    def geo_migration?
      self.class.metadata[:geo]
    end
  end
end
