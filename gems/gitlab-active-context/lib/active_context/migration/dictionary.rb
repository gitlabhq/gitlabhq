# frozen_string_literal: true

module ActiveContext
  class Migration
    class Dictionary
      Error = Class.new(StandardError)
      DuplicateVersionError = Class.new(Error)
      InvalidMigrationNameError = Class.new(Error)

      class << self
        def migrations_path
          Array(ActiveContext::Config.migrations_path)
        end

        def instance
          @instance ||= new
        end

        delegate :migrations, to: :instance
      end

      def initialize
        @migrations = {}
        load_migrations
      end

      # Returns all migrations sorted by version
      def migrations
        @migrations.sort_by { |version, _| version }.map(&:last)
      end

      # Find a specific migration by version
      def find_by_version(version)
        @migrations[version.to_s]
      end

      private

      def load_migrations
        migration_files.each do |file|
          version, name = parse_migration_file(file)
          version_constant = :"V#{version}"

          # Only define the module if it doesn't exist
          if ActiveContext::Migration.const_defined?(version_constant)
            migration_module = ActiveContext::Migration.const_get(version_constant, false)
          else
            migration_module = Module.new
            ActiveContext::Migration.const_set(version_constant, migration_module)

            # Evaluate the migration file content within the namespace
            migration_content = File.read(file)
            migration_module.module_eval(migration_content)
          end

          klass_name = name.camelize
          begin
            # Look up the class within our namespace
            klass = migration_module.const_get(klass_name, false)
          rescue NameError
            raise InvalidMigrationNameError, "Could not find migration class '#{klass_name}' in #{file}"
          end

          if @migrations.key?(version)
            raise DuplicateVersionError, "Multiple migrations have the version number #{version}"
          end

          @migrations[version] = klass
        end
      end

      def migration_files
        self.class.migrations_path.flat_map do |path|
          Dir[File.join(path, '*.rb')]
        end
      end

      def parse_migration_file(filename)
        basename = File.basename(filename, '.rb')

        if basename =~ /\A([0-9]{14})_(.+)\z/
          version = ::Regexp.last_match(1)
          name = ::Regexp.last_match(2)
          [version, name]
        else
          raise InvalidMigrationNameError,
            "Invalid migration file name format: #{basename}. Expected format: YYYYMMDDHHMMSS_name.rb"
        end
      end
    end
  end
end
