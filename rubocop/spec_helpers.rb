module RuboCop
  module SpecHelpers
    SPEC_HELPERS = %w[fast_spec_helper.rb rails_helper.rb spec_helper.rb].freeze
    MIGRATION_SPEC_DIRECTORIES = ['spec/migrations', 'spec/lib/gitlab/background_migration'].freeze
    CONTROLLER_SPEC_DIRECTORIES = ['spec/controllers', 'spec/support/shared_examples/controllers'].freeze

    # Returns true if the given node originated from the spec directory.
    def in_spec?(node)
      path = node.location.expression.source_buffer.name
      pwd = RuboCop::PathUtil.pwd

      !SPEC_HELPERS.include?(File.basename(path)) &&
        path.start_with?(File.join(pwd, 'spec'), File.join(pwd, 'ee', 'spec'))
    end

    def migration_directories
      @migration_directories ||= MIGRATION_SPEC_DIRECTORIES.map do |dir|
        pwd = RuboCop::PathUtil.pwd
        [File.join(pwd, dir), File.join(pwd, 'ee', dir)]
      end.flatten
    end

    # Returns true if the given node originated from a migration spec.
    def in_migration_spec?(node)
      path = node.location.expression.source_buffer.name

      in_spec?(node) &&
        path.start_with?(*migration_directories)
    end

    def controller_directories
      @controller_directories ||= CONTROLLER_SPEC_DIRECTORIES.map do |dir|
        pwd = RuboCop::PathUtil.pwd
        [File.join(pwd, dir), File.join(pwd, 'ee', dir)]
      end.flatten
    end

    # Returns true if the given node originated from a controller spec.
    def in_controller_spec?(node)
      path = node.location.expression.source_buffer.name

      in_spec?(node) &&
        path.start_with?(*controller_directories)
    end
  end
end
