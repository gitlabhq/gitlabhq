# frozen_string_literal: true

require 'gitlab/housekeeper/keep'
require_relative '../helpers/file_helper'

module Keeps
  class CleanupUnusedIndexes < ::Gitlab::Housekeeper::Keep
    class MigrationBuilder
      Result = Struct.new(:migration_file, :migration_number, :digest_file, keyword_init: true)

      def build(ctx)
        migration_file, migration_number = generate_migration_file(ctx)
        digest_file = write_schema_digest(migration_number)

        Result.new(
          migration_file: migration_file,
          migration_number: migration_number,
          digest_file: digest_file
        )
      end

      private

      def generate_migration_file(ctx)
        migration_name = unique_migration_name_for(ctx[:name])
        generator = ::PostDeploymentMigration::PostDeploymentMigrationGenerator.new([migration_name])

        migration_file = generator.invoke_all.first
        file_helper = ::Keeps::Helpers::FileHelper.new(migration_file)
        file_helper.replace_method_content(:change, migration_body_for(ctx), strip_comments_from_file: true)

        ::Gitlab::Housekeeper::Shell.rubocop_autocorrect(migration_file)

        [migration_file, generator.migration_number]
      end

      # Cop/FilenameLength caps migration filenames at 100 chars; the SHA
      # suffix disambiguates names that would otherwise truncate to the same.
      def unique_migration_name_for(index_name)
        base = "remove_unused_index_#{index_name}"
        return base if base.length <= 80

        suffix = Digest::SHA256.hexdigest(index_name)[0, 8]
        "#{base[0, 80]}_#{suffix}"
      end

      def write_schema_digest(migration_number)
        digest = Digest::SHA256.hexdigest(migration_number)
        digest_file = Pathname.new('db').join('schema_migrations', migration_number.to_s).to_s
        File.open(digest_file, 'w') { |f| f.write(digest) }
        digest_file
      end

      def migration_body_for(ctx)
        # to_sym.inspect produces :foo or :"odd-name", keeping the output
        # valid Ruby even when an index or table name needs quoting.
        <<~RUBY.strip
          disable_ddl_transaction!

            TABLE_NAME = #{ctx[:tablename].to_sym.inspect}
            INDEX_NAME = #{ctx[:name].to_sym.inspect}
            COLUMN_NAMES = #{ctx[:columns].inspect}

            def up
              remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
            end

            def down
              add_concurrent_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
            end
        RUBY
      end
    end
  end
end
