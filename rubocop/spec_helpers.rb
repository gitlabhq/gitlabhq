module RuboCop
  module SpecHelpers
    SPEC_HELPERS = %w[fast_spec_helper.rb rails_helper.rb spec_helper.rb].freeze
    MIGRATION_SPEC_DIRECTORIES = ['spec/migrations', 'spec/lib/gitlab/background_migration'].freeze

    # Returns true if the given node originated from the spec directory.
    def in_spec?(node)
      path = node.location.expression.source_buffer.name

      !SPEC_HELPERS.include?(File.basename(path)) &&
        path.start_with?(File.join(Dir.pwd, 'spec'), File.join(Dir.pwd, 'ee', 'spec'))
    end

    def migration_directories
      @migration_directories ||= MIGRATION_SPEC_DIRECTORIES.map do |dir|
        [File.join(Dir.pwd, dir), File.join(Dir.pwd, 'ee', dir)]
      end.flatten
    end

    # Returns true if the given node originated from a migration spec.
    def in_migration_spec?(node)
      path = node.location.expression.source_buffer.name

      in_spec?(node) &&
        path.start_with?(*migration_directories)
    end
  end
end
