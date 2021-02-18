# frozen_string_literal: true

module RuboCop
  # Module containing helper methods for writing QA cops.
  module QAHelpers
    # Returns true if the given node originated from the qa/ directory.
    def in_qa_file?(node)
      path = node.location.expression.source_buffer.name

      path.start_with?(File.join(Dir.pwd, 'qa'))
    end
  end
end
