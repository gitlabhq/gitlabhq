# frozen_string_literal: true

module ClickHouse
  class Migration
    cattr_accessor :verbose, :client_configuration
    attr_accessor :name, :version

    def initialize(connection, name = self.class.name, version = nil)
      @connection = connection
      @name    = name
      @version = version
    end

    self.verbose = true

    MIGRATION_FILENAME_REGEXP = /\A([0-9]+)_([_a-z0-9]*)\.?([_a-z0-9]*)?\.rb\z/

    def execute(query)
      connection.execute(query)
    end

    def up
      return unless self.class.respond_to?(:up)

      self.class.up
    end

    def down
      return unless self.class.respond_to?(:down)

      self.class.down
    end

    # Execute this migration in the named direction
    def migrate(direction)
      return unless respond_to?(direction)

      case direction
      when :up   then announce 'migrating'
      when :down then announce 'reverting'
      end

      time = Benchmark.measure do
        exec_migration(direction)
      end

      case direction
      when :up   then announce format("migrated (%.4fs)", time.real)
                      write
      when :down then announce format("reverted (%.4fs)", time.real)
                      write
      end
    end

    private

    attr_reader :connection

    def exec_migration(direction)
      # noinspection RubyCaseWithoutElseBlockInspection
      case direction
      when :up then up
      when :down then down
      end
    end

    def write(text = '')
      $stdout.puts(text) if verbose
    end

    def announce(message)
      text = "#{version} #{name}: #{message}"
      length = [0, 75 - text.length].max
      write format('== %s %s', text, '=' * length)
    end
  end
end
