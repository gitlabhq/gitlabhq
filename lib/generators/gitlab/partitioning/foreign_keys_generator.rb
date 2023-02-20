# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record/migration'

module Gitlab
  module Partitioning
    class ForeignKeysGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      desc 'This generator creates the migrations needed for updating the foreign keys when partitioning the tables'

      source_root File.expand_path('templates', __dir__)

      class_option :target, type: :string, required: true, desc: 'Target table name'
      class_option :source, type: :string, required: true, desc: 'Source table name'
      class_option :partitioning_column, type: :string, default: :partition_id,
        desc: 'The column that is used for partitioning'
      class_option :database, type: :string, default: :ci,
        desc: 'Database name connection'

      def create_fk_index_migration
        migration_template(
          '../templates/foreign_key_index.rb.template',
         fk_index_file_name)
      end

      def create_fk_definition_migration
        migration_template(
          '../templates/foreign_key_definition.rb.template',
          fk_definition_file_name)
      end

      def create_fk_validation_migration
        migration_template(
          '../templates/foreign_key_validation.rb.template',
          fk_validation_file_name)
      end

      def remove_old_fk_migration
        migration_template(
          '../templates/foreign_key_removal.rb.template',
          fk_removal_file_name)
      end

      private

      def fk_index_file_name
        post_migration_file_path(
          "add_fk_index_to_#{source_table_name}_on_#{partitioning_column}_and_#{foreign_key_column}.rb")
      end

      def fk_definition_file_name
        post_migration_file_path(
          "add_fk_to_#{source_table_name}_on_#{partitioning_column}_and_#{foreign_key_column}.rb")
      end

      def fk_validation_file_name
        post_migration_file_path(
          "validate_fk_on_#{source_table_name}_#{partitioning_column}_and_#{foreign_key_column}.rb")
      end

      def fk_removal_file_name
        post_migration_file_path(
          "remove_fk_to_#{target_table_name}_#{source_table_name}_on_#{foreign_key_column}.rb")
      end

      def post_migration_file_path(name)
        File.join(db_migrate_path, name)
      end

      def db_migrate_path
        super.sub('migrate', 'post_migrate')
      end

      def source_table_name
        options[:source]
      end

      def target_table_name
        options[:target]
      end

      def partitioning_column
        options[:partitioning_column]
      end

      def foreign_keys_candidates
        connection
          .foreign_keys(source_table_name)
          .select { |fk| fk.to_table == target_table_name }
          .reject { |fk| fk.name.end_with?('_p') }
      end

      def fk_candidate
        @fk_candidate ||= select_foreign_key
      end

      def foreign_key_name
        fk_candidate.name
      end

      def partitioned_foreign_key_name
        "#{foreign_key_name}_p"
      end

      def foreign_key_column
        fk_candidate.column
      end

      def fk_on_delete_option
        fk_candidate.on_delete
      end

      def fk_target_column
        fk_candidate.primary_key
      end

      def connection
        Gitlab::Database
          .database_base_models
          .fetch(options[:database])
          .connection
      end

      def select_foreign_key
        case foreign_keys_candidates.size
        when 0
          raise Thor::InvocationError, "No FK found between #{source_table_name} and #{target_table_name}"
        when 1
          foreign_keys_candidates.first
        else
          select_fk_from_user_input
        end
      end

      def select_fk_from_user_input
        options = (0...foreign_keys_candidates.size).to_a.map(&:to_s)

        say "There are multiple FKs between #{source_table_name} and #{target_table_name}:"
        foreign_keys_candidates.each.with_index do |fk, index|
          say "\t#{index} : #{fk}"
        end

        input = ask("Please select one:", limited_to: options, default: '0')

        foreign_keys_candidates.fetch(input.to_i)
      end
    end
  end
end
