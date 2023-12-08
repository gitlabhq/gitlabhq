# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        class TextTemplate
          MAX_BLOCKS = 10_000

          def initialize(content, ctx)
            @content = content
            @ctx = Interpolation::Context.fabricate(ctx)
            @errors = []
            @blocks = {}

            interpolate! if valid?
          end

          def valid?
            errors.none?
          end

          def errors
            @errors + ctx.errors + blocks.values.flat_map(&:errors)
          end

          def interpolated
            @result if valid?
          end

          private

          attr_reader :blocks, :content, :ctx

          def interpolate!
            return @errors.push('config too large') if content.bytesize > max_total_yaml_size_bytes

            @result = Interpolation::Block.match(content) do |matched, data|
              block = (blocks[matched] ||= Interpolation::Block.new(matched, data, ctx))

              break @errors.push('too many interpolation blocks') if blocks.count > MAX_BLOCKS
              break unless block.valid?

              if block.value.is_a?(String)
                block.value
              else
                block.value.to_json
              end
            end
          end

          def max_total_yaml_size_bytes
            Gitlab::CurrentSettings.current_application_settings.ci_max_total_yaml_size_bytes
          end
        end
      end
    end
  end
end
