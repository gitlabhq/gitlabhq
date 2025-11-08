# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        ##
        # Performs CI config file interpolation, and surfaces all possible interpolation errors.
        #
        class Interpolator
          attr_reader :config, :args, :yaml_context, :external_context, :errors

          def initialize(config, args, yaml_context, external_context: nil)
            @config = config
            @args = args.nil? ? {} : args
            @yaml_context = yaml_context
            @external_context = external_context
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
            return @errors.push(_('Given inputs must be a hash')) unless args.is_a?(Hash)

            if inputs_without_header?
              return @errors.push(
                _('Given inputs not defined in the `spec` section of the included configuration file'))
            end

            return @result ||= config.content unless config.has_header?

            return @errors.concat(header.errors) unless header.valid?
            return @errors.concat(inputs.errors) unless inputs.valid?

            return if @errors.any?
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
            @entry ||= Header::Root.new(config.header || {}).tap do |header|
              header.key = 'header'

              header.compose!
            end
          end

          def content
            @content ||= config.content
          end

          def spec
            @spec ||= begin
              full_spec = header.spec_entry.value || {}
              if full_spec[:include].present? && external_context
                processor = External::Header::Processor.new(full_spec, external_context)
                processed_spec = processor.perform
                processed_spec[:inputs] || {}
              else
                full_spec[:inputs] || {}
              end
            end
          rescue External::Header::Processor::IncludeError => e
            @errors.push(e.message)
            {}
          end

          def inputs
            @inputs ||= Inputs.new(spec, args)
          end

          def context
            @context ||= Context.new(
              { inputs: inputs.to_hash, component: component_data }, variables: yaml_context.variables
            )
          end

          def template
            @template ||= Template.new(content, context)
          end

          def component_data
            yaml_context.component.slice(*header.spec_component_value)
          end
        end
      end
    end
  end
end
