module RuboCop
  module SpecHelpers
    SPEC_HELPERS = %w[spec_helper.rb rails_helper.rb].freeze

    # Returns true if the given node originated from the spec directory.
    def in_spec?(node)
      path = node.location.expression.source_buffer.name

      !SPEC_HELPERS.include?(File.basename(path)) &&
        path.start_with?(File.join(Dir.pwd, 'spec'), File.join(Dir.pwd, 'ee', 'spec'))
    end

    # Returns true if the given node originated from a migration spec.
    def in_migration_spec?(node)
      path = node.location.expression.source_buffer.name

      in_spec?(node) &&
        path.start_with?(
          File.join(Dir.pwd, 'spec', 'migrations'),
          File.join(Dir.pwd, 'ee', 'spec', 'migrations'))
    end
  end
end
