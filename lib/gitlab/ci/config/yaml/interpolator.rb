# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Yaml
        ##
        # Config::Yaml::Interpolator performs CI config file interpolation, and surfaces all possible interpolation
        # errors. It is designed to provide an external file's validation context too.
        #
        class Interpolator
          attr_reader :config, :args, :errors

          def initialize(config, args)
            @config = config
            @args = args.to_h
            @errors = []
            @interpolated = false
          end

          def valid?
            @errors.none?
          end

          def to_hash
            @result.to_h
          end

          def error_message
            # Interpolator can have multiple error messages, like: ["interpolation interrupted by errors", "unknown
            # interpolation key: `abc`"] ?
            #
            # We are joining them together into a single one, because only one error can be surfaced when an external
            # file gets included and is invalid. The limit to three error messages combined is more than required.
            #
            @errors.first(3).join(', ')
          end

          def interpolate!
            return @errors.push(config.error) unless config.valid?
            return @errors.push('unknown input arguments') if inputs_without_header?
            return @result ||= config.content unless config.has_header?

            return @errors.concat(header.errors) unless header.valid?
            return @errors.concat(inputs.errors) unless inputs.valid?
            return @errors.concat(context.errors) unless context.valid?
            return @errors.concat(template.errors) unless template.valid?

            @interpolated = true

            @result ||= template.interpolated.to_h.deep_symbolize_keys
          end

          def interpolated?
            @interpolated
          end

          private

          def inputs_without_header?
            args.any? && !config.has_header?
          end

          def header
            @entry ||= Ci::Config::Header::Root.new(config.header).tap do |header|
              header.key = 'header'

              header.compose!
            end
          end

          def content
            @content ||= config.content
          end

          def spec
            @spec ||= header.inputs_value
          end

          def inputs
            @inputs ||= if Feature.enabled?(:ci_interpolation_inputs_refactor)
                          Ci::Interpolation::Inputs.new(spec, args)
                        else
                          Ci::Input::Inputs.new(spec, args)
                        end
          end

          def context
            @context ||= Ci::Interpolation::Context.new({ inputs: inputs.to_hash })
          end

          def template
            @template ||= ::Gitlab::Ci::Interpolation::Template
              .new(content, context)
          end
        end
      end
    end
  end
end
