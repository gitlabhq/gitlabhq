# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module API
      # Checks that API desc blocks do not contain lifecycle terms
      # (experiment, experimental, beta, general availability, GA) in the description or detail strings.
      # Use `route_setting :lifecycle, :experiment` or
      # `route_setting :lifecycle, :beta` instead.
      #
      # @example
      #
      #   # bad
      #   desc 'Get all widgets' do
      #     detail 'This feature is experimental.'
      #     tags %w[widgets]
      #   end
      #
      #   # bad
      #   desc '[BETA] Get all widgets' do
      #     detail 'Introduced in GitLab 18.10.'
      #     tags %w[widgets]
      #   end
      #
      #   # good
      #   route_setting :lifecycle, :experiment
      #   desc 'Get all widgets' do
      #     detail 'Introduced in GitLab 18.10.'
      #     tags %w[widgets]
      #   end
      #
      #   # good
      #   route_setting :lifecycle, :beta
      #   desc 'Get all widgets' do
      #     detail 'Introduced in GitLab 18.10.'
      #     tags %w[widgets]
      #   end
      class LifecycleInDescription < RuboCop::Cop::Base
        include CodeReuseHelpers

        MSG = 'Do not use lifecycle terms (experiment, beta, general availability, GA) in API descriptions. ' \
          'Use `route_setting :lifecycle, :experiment` or `route_setting :lifecycle, :beta` instead. ' \
          'https://docs.gitlab.com/development/api_styleguide/#marking-endpoint-lifecycle'

        LIFECYCLE_PATTERN = /\b(?:experiment(?:al)?|beta|general availability|GA)\b/i

        # @!method desc_block(node)
        def_node_matcher :desc_block, <<~PATTERN
          (block
            (send nil? :desc ${str dstr} ...)
            _args
            $_body
          )
        PATTERN

        # @!method desc_block_no_summary(node)
        def_node_matcher :desc_block_no_summary, <<~PATTERN
          (block
            (send nil? :desc ...)
            _args
            $_body
          )
        PATTERN

        # @!method detail_string(node)
        def_node_matcher :detail_string, '(send nil? :detail ${str dstr})'

        def on_block(node)
          return unless node.method?(:desc)

          check_summary(node)
          check_detail(node)
        end

        alias_method :on_numblock, :on_block

        private

        def check_summary(node)
          summary_node, = desc_block(node)
          return unless summary_node

          text = extract_text(summary_node)
          return unless text&.match?(LIFECYCLE_PATTERN)

          add_offense(summary_node)
        end

        def check_detail(node)
          body = desc_block_no_summary(node) || desc_block(node)&.last
          return unless body

          find_detail_nodes(body).each do |detail_node|
            text = extract_text(detail_node)
            next unless text&.match?(LIFECYCLE_PATTERN)

            add_offense(detail_node)
          end
        end

        def find_detail_nodes(body)
          return [] unless body

          if body.send_type? && body.method?(:detail)
            value = detail_string(body)
            return value ? [value] : []
          end

          return [] unless body.begin_type?

          body.children.filter_map do |child|
            next unless child.send_type? && child.method?(:detail)

            detail_string(child)
          end
        end

        def extract_text(node)
          case node.type
          when :str
            node.value
          when :dstr
            node.children.select { |child| child.is_a?(Parser::AST::Node) && child.str_type? }
                .map(&:value).join
          end
        end
      end
    end
  end
end
