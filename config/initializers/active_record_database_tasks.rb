# frozen_string_literal: true

module ActiveRecord
  module Tasks
    module DatabaseTasks
      def migrate_status
        # rubocop:disable Database/MultipleDatabases -- From Rails base code which doesn't follow our style guide
        # rubocop:disable Rails/Output -- From Rails base code which doesn't follow our style guide
        unless ActiveRecord::Base.connection.schema_migration.table_exists?
          Kernel.abort "Schema migrations table does not exist yet."
        end

        puts "\ndatabase: #{ActiveRecord::Base.connection_db_config.database}\n\n"
        puts "#{'Status'.center(8)}  #{'Migration ID'.ljust(14)}  #{'Type'.ljust(7)}  #{'Milestone'.ljust(11)}  Name"
        puts "-" * 50
        status_with_milestones.each do |status, version, type, milestone, name|
          puts "#{status.center(8)}  #{version.ljust(14)}  #{type.ljust(7)}  #{milestone.ljust(11)}  #{name}"
        end
        puts
        # rubocop:enable Rails/Output
        # rubocop:enable Database/MultipleDatabases
      end

      def status_with_milestones
        # rubocop:disable Database/MultipleDatabases -- From Rails base code which doesn't follow our style guide
        versions = ActiveRecord::SchemaMigration.all_versions.map(&:to_i)
        ActiveRecord::Base.connection.migration_context.migrations.sort_by(&:version).map do |m|
          [
            (versions.include?(m.version.to_i) ? 'up' : 'down'),
            m.version.to_s,
            m.version.try(:type).to_s,
            m.try(:milestone).to_s,
            m.name
          ]
        end
        # rubocop:enable Database/MultipleDatabases
      end
    end
  end
end

return unless Gitlab.ee?

ActiveSupport.on_load(:active_record) do
  Gitlab::Patch::AdditionalDatabaseTasks.patch!
end
