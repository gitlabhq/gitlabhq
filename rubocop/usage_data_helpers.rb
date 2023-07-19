# frozen_string_literal: true

module RuboCop
  module UsageDataHelpers
    def in_usage_data_file?(node)
      filepath(node).end_with?('gitlab/usage_data.rb')
    end

    def in_instrumentation_file?(node)
      filepath(node).start_with?('lib/gitlab/usage/metrics/instrumentations') && File.extname(filepath(node)) == '.rb'
    end

    private

    def filepath(node)
      node.location.expression.source_buffer.name
    end
  end
end
