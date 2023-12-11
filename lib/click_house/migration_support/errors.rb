# frozen_string_literal: true

module ClickHouse
  module MigrationSupport
    module Errors
      class Base < StandardError
        def initialize(message = nil)
          message = "\n\n#{message}\n\n" if message
          super
        end
      end

      class IllegalMigrationNameError < Base
        def initialize(name = nil)
          if name
            super("Illegal name for migration file: #{name}\n\t(only lower case letters, numbers, and '_' allowed).")
          else
            super('Illegal name for migration.')
          end
        end
      end

      IrreversibleMigration = Class.new(Base)
      LockError = Class.new(Base)

      class DuplicateMigrationVersionError < Base
        def initialize(version = nil)
          if version
            super("Multiple migrations have the version number #{version}.")
          else
            super('Duplicate migration version error.')
          end
        end
      end

      class DuplicateMigrationNameError < Base
        def initialize(name = nil)
          if name
            super("Multiple migrations have the name #{name}.")
          else
            super('Duplicate migration name.')
          end
        end
      end

      class UnknownMigrationVersionError < Base
        def initialize(version = nil)
          if version
            super("No migration with version number #{version}.")
          else
            super('Unknown migration version.')
          end
        end
      end
    end
  end
end
