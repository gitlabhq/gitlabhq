module RuboCop
  # Module containing helper methods for writing migration cops.
  module MigrationHelpers
    # Returns true if the given node originated from the db/migrate directory.
    def in_migration?(node)
      dirname = File.dirname(node.location.expression.source_buffer.name)

      dirname.end_with?('db/migrate', 'db/post_migrate')
    end

    def in_post_deployment_migration?(node)
      dirname = File.dirname(node.location.expression.source_buffer.name)

      dirname.end_with?('db/post_migrate')
    end
  end
end
