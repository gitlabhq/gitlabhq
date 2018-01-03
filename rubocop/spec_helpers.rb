module RuboCop
  module SpecHelpers
    SPEC_HELPERS = %w[spec_helper.rb rails_helper.rb].freeze

    # Returns true if the given node originated from the spec directory.
    def in_spec?(node)
      path = node.location.expression.source_buffer.name

      !SPEC_HELPERS.include?(File.basename(path)) && path.start_with?(File.join(Dir.pwd, 'spec'))
    end
  end
end
