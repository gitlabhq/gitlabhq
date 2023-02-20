# frozen_string_literal: true

module Gitlab
  module Ci
    module Interpolation
      class Template
        include Gitlab::Utils::StrongMemoize

        attr_reader :blocks, :ctx

        TooManyBlocksError = Class.new(StandardError)
        InvalidBlockError = Class.new(StandardError)

        MAX_BLOCKS = 10_000

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
          @result = @config.replace! do |data|
            Interpolation::Block.match(data) do |block, data|
              evaluate_block(block, data)
            end
          end
        rescue TooManyBlocksError
          @errors.push('too many interpolation blocks')
        rescue InvalidBlockError
          @errors.push('interpolation interrupted by errors')
        end
        strong_memoize_attr :interpolate!

        def evaluate_block(block, data)
          block = (@blocks[block] ||= Interpolation::Block.new(block, data, ctx))

          raise TooManyBlocksError if @blocks.count > MAX_BLOCKS
          raise InvalidBlockError unless block.valid?

          block.value
        end
      end
    end
  end
end
