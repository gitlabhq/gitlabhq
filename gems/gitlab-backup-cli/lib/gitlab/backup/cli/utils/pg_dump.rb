# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Utils
        class PgDump
          # Expose snapshot_id to be used when creating a database dump
          # See https://www.postgresql.org/docs/14/functions-admin.html#FUNCTIONS-SNAPSHOT-SYNCHRONIZATION
          attr_reader :snapshot_id
          # Dump only specified database schemas instead of everything
          attr_reader :schemas
          # Database name
          attr_reader :database_name
          # Additional ENV variables to use when running PgDump
          attr_reader :env

          # @param [String] database_name
          # @param [String] snapshot_id the snapshot id to use when creating a database dump
          # @param [Array<String>] schemas
          # @param [Hash<String,String>] env
          def initialize(database_name:, snapshot_id: nil, schemas: [], env: {})
            @database_name = database_name
            @snapshot_id = snapshot_id
            @schemas = schemas
            @env = env
          end

          # Spawn a pg_dump process and assign a given output IO
          #
          # @param [IO] output the output IO
          def spawn(output:)
            Process.spawn(env, 'pg_dump', *cmd_args, out: output)
          end

          def build_command
            Shell::Command.new('pg_dump', *cmd_args, env: env)
          end

          private

          # Returns a list of arguments used by the pg_dump command
          #
          # @return [Array<String (frozen)>]
          def cmd_args
            args = ["--clean"] # Pass '--clean' to include 'DROP TABLE' statements in the DB dump.
            args << '--if-exists'
            args << "--snapshot=#{snapshot_id}" if snapshot_id

            schemas.each do |schema|
              args << '-n'
              args << schema
            end

            args << database_name

            args
          end
        end
      end
    end
  end
end
