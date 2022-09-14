# frozen_string_literal: true

module RuboCop
  module Cop
    # Checks for a leading '/' in route redirects
    # For more information see: https://gitlab.com/gitlab-org/gitlab-foss/issues/50645
    #
    # @example
    #   # bad
    #   root to: redirect('/-/autocomplete/users')
    #
    #   # good
    #   root to: redirect('-/autocomplete/users')
    #

    class AvoidRouteRedirectLeadingSlash < RuboCop::Cop::Base
      extend RuboCop::Cop::AutoCorrector

      MSG = 'Do not use a leading "/" in route redirects'

      def_node_matcher :leading_slash_in_redirect?, <<~PATTERN
        (send nil? :redirect (str #has_leading_slash?))
      PATTERN

      def on_send(node)
        return unless in_routes?(node)
        return unless leading_slash_in_redirect?(node)

        add_offense(node) do |corrector|
          corrector.replace(node.loc.expression, remove_leading_slash(node))
        end
      end

      def has_leading_slash?(str)
        str.start_with?("/")
      end

      def in_routes?(node)
        path = node.location.expression.source_buffer.name
        dirname = File.dirname(path)
        filename = File.basename(path)
        dirname.end_with?('config/routes') || filename.end_with?('routes.rb')
      end

      def remove_leading_slash(node)
        node.source.sub('/', '')
      end
    end
  end
end
