# frozen_string_literal: true

module RuboCop
  # Module containing helper methods for writing migration cops.
  module MigrationHelpers
    # Tables with permanently small number of records
    SMALL_TABLES = %i[
      application_settings
      plan_limits
    ].freeze

    # Tables with large number of columns (> 50 on GitLab.com as of 01/2021)
    WIDE_TABLES = %i[
      ci_builds
      namespaces
      projects
      users
    ].freeze

    # List of helpers that add new columns, either directly (ADD_COLUMN_METHODS)
    # or through a create/alter table (TABLE_METHODS)
    ADD_COLUMN_METHODS = %i(add_column add_column_with_default change_column_type_concurrently).freeze

    TABLE_METHODS = %i(create_table create_table_if_not_exists change_table create_table_with_constraints).freeze

    def high_traffic_tables
      @high_traffic_tables ||= rubocop_migrations_config.dig('Migration/UpdateLargeTable', 'HighTrafficTables')
    end

    # Returns true if the given node originated from the db/migrate directory.
    def in_migration?(node)
      in_deployment_migration?(node) || in_post_deployment_migration?(node)
    end

    def in_deployment_migration?(node)
      dirname(node).end_with?('db/migrate', 'db/geo/migrate')
    end

    def in_post_deployment_migration?(node)
      dirname(node).end_with?('db/post_migrate', 'db/geo/post_migrate')
    end

    def version(node)
      File.basename(node.location.expression.source_buffer.name).split('_').first.to_i
    end

    # Returns true if a column definition is for an array
    # rubocop:disable Lint/BooleanSymbol
    def array_column?(node)
      node.each_descendant(:pair).any? do |pair_node|
        pair_node.child_nodes[0].value == :array && # Searching for a (pair (sym :array) (true)) node
        pair_node.child_nodes[1].type == :true # RuboCop::AST::Node uses symbols for types, even when that is a :true
      end
    end
    # rubocop:enable Lint/BooleanSymbol

    private

    def dirname(node)
      File.dirname(node.location.expression.source_buffer.name)
    end

    def rubocop_migrations_config
      @rubocop_migrations_config ||= YAML.load_file(File.join(rubocop_path, 'rubocop-migrations.yml'))
    end

    def rubocop_path
      File.expand_path(__dir__)
    end
  end
end
