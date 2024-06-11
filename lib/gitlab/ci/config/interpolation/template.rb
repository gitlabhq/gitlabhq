# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        class Template
          attr_reader :blocks, :ctx

          MAX_BLOCKS = 10_000
          BLOCK_REGEXP = Gitlab::UntrustedRegexp.new('(?<block>\$\[\[\s*(?<data>\S{1}.*?\S{1})\s*\]\])')
          BLOCK_PREFIX = '$[['

          def initialize(config, ctx)
            @config = Interpolation::Config.fabricate(config)
            @ctx = Interpolation::Context.fabricate(ctx)
            @errors = []
            @blocks = {}

            interpolate! if valid?
          end

          def valid?
            errors.none?
          end

          def errors
            @errors + @config.errors + @ctx.errors + @blocks.values.flat_map(&:errors)
          end

          def size
            @blocks.size
          end

          def interpolated
            @result if valid?
          end

          private

          def interpolate!
            @result = @config.replace! do |node|
              break if @errors.any?
              next node unless node_might_contain_interpolation_block?(node)

              matches = BLOCK_REGEXP.scan(node)
              next node if matches.empty?

              blocks = interpolate_blocks(matches)
              break unless @errors.none? && blocks.present?

              get_interpolated_node_content!(node, blocks)
            end
          end

          def node_might_contain_interpolation_block?(node)
            node.is_a?(String) && node.include?(BLOCK_PREFIX)
          end

          def interpolate_blocks(matches)
            matches.map do |match, data|
              block = (@blocks[match] ||= Interpolation::Block.new(match, data, ctx))

              break @errors.push('too many interpolation blocks') if @blocks.size > MAX_BLOCKS
              break unless block.valid?

              block
            end
          end

          def get_interpolated_node_content!(node, blocks)
            if used_inside_a_string?(node, blocks)
              interpolate_string_node!(node, blocks)
            else
              blocks.first.value
            end
          end

          def interpolate_string_node!(node, blocks)
            blocks.reduce(node) do |interpolated_node, block|
              interpolated_node.gsub(block.to_s, block.value.to_s)
            end
          end

          def used_inside_a_string?(node, blocks)
            blocks.count > 1 || node.length != blocks.first.length
          end
        end
      end
    end
  end
end
