module RuboCop
  # Module containing helper methods for writing migration cops.
  module MigrationHelpers
    # Returns true if the given node originated from the db/migrate directory.
    def in_migration?(node)
      dirname(node).end_with?('db/migrate', 'db/geo/migrate') || in_post_deployment_migration?(node)
    end

    def in_post_deployment_migration?(node)
      dirname(node).end_with?('db/post_migrate', 'db/geo/post_migrate')
    end

    def version(node)
      File.basename(node.location.expression.source_buffer.name).split('_').first.to_i
    end

    private

    def dirname(node)
      File.dirname(node.location.expression.source_buffer.name)
    end
  end
end
