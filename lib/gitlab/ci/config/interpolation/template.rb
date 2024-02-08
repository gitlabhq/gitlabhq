# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        class Template
          include Gitlab::Utils::StrongMemoize

          attr_reader :blocks, :ctx

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
              break if @errors.any?

              Interpolation::Block.match(data) do |block, data|
                block = (@blocks[block] ||= Interpolation::Block.new(block, data, ctx))

                break @errors.push('too many interpolation blocks') if @blocks.size > MAX_BLOCKS
                break unless block.valid?

                block.value
              end
            end
          end
          strong_memoize_attr :interpolate!
        end
      end
    end
  end
end
