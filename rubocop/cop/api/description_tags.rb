# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module API
      # Checks that API desc blocks define tags
      #
      # @example
      #
      #   # bad
      #   desc 'Get a specific environment' do
      #     success Entities::Environment
      #     failure [
      #       { code: 401, message: 'Unauthorized' },
      #       { code: 404, message: 'Not found' }
      #     ]
      #   end
      #
      #   # good
      #   desc 'Get a specific environment' do
      #     success Entities::Environment
      #     failure [
      #       { code: 401, message: 'Unauthorized' },
      #       { code: 404, message: 'Not found' }
      #     ]
      #     tags %w[environments]
      #   end
      #
      #   # good
      #   desc 'Create a new environment' do
      #     detail 'Creates a new environment'
      #     tags environments_tags
      #   end
      class DescriptionTags < RuboCop::Cop::Base
        include CodeReuseHelpers
        extend AutoCorrector

        MSG = 'API desc blocks must define tags. See https://docs.gitlab.com/development/api_styleguide#choosing-a-tag.'

        # @!method desc_block(node)
        def_node_matcher :desc_block, <<~PATTERN
          (block
            (send nil? :desc ...)
            _args
            $_body
          )
        PATTERN

        # @!method has_tags?(node)
        def_node_matcher :has_tags?, <<~PATTERN
          `(send nil? :tags ...)
        PATTERN

        RESTRICT_ON_SEND = %i[desc].freeze

        def on_send(node)
          parent = node.each_ancestor(:block).first
          return unless parent

          body = desc_block(parent)
          return unless body

          return if has_tags?(body)

          add_offense(node) do |corrector|
            autocorrect(corrector, parent, body)
          end
        end
        alias_method :on_csend, :on_send

        private

        def autocorrect(corrector, block_node, body_node)
          tag = determine_tag(block_node)
          tags_line = "#{indent(body_node || block_node)}tags %w[#{tag}]\n"

          # Insert before the closing 'end' of the block
          corrector.insert_before(block_node.loc.end, tags_line)
        end

        def determine_tag(block_node)
          # Try to determine the tag from the file path
          file_path = block_node.source_range.source_buffer.name
          File.basename(file_path, ".rb")
        end
      end
    end
  end
end
