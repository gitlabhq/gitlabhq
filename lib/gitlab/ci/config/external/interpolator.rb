# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        ##
        # Config::External::Interpolation perform includable file interpolation, and surfaces all possible interpolation
        # errors. It is designed to provide an external file's validation context too.
        #
        class Interpolator
          include ::Gitlab::Utils::StrongMemoize

          attr_reader :config, :args, :ctx, :errors

          def initialize(config, args, ctx = nil)
            @config = config
            @args = args.to_h
            @ctx = ctx
            @errors = []

            validate!
          end

          def valid?
            @errors.none?
          end

          def ready?
            ##
            # Interpolation is ready when it has been either interrupted by an error or finished with a result.
            #
            @result || @errors.any?
          end

          def interpolate?
            enabled? && has_header? && valid?
          end

          def has_header?
            config.has_header? && config.header.present?
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

          ##
          # TODO Add `instrument.logger` instrumentation blocks:
          #   https://gitlab.com/gitlab-org/gitlab/-/issues/396722
          #
          def interpolate!
            return {} unless valid?
            return @result ||= content.to_h unless interpolate?

            return @errors.concat(header.errors) unless header.valid?
            return @errors.concat(inputs.errors) unless inputs.valid?
            return @errors.concat(context.errors) unless context.valid?
            return @errors.concat(template.errors) unless template.valid?

            if ctx&.user
              ::Gitlab::UsageDataCounters::HLLRedisCounter.track_event('ci_interpolation_users', values: ctx.user.id)
            end

            @result ||= template.interpolated.to_h.deep_symbolize_keys
          end
          strong_memoize_attr :interpolate!

          private

          def validate!
            return errors.push('content does not have a valid YAML syntax') unless config.valid?

            return unless has_header? && !enabled?

            errors.push('can not evaluate included file because interpolation is disabled')
          end

          def enabled?
            return false if ctx.nil?

            ::Feature.enabled?(:ci_includable_files_interpolation, ctx.project)
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
            @inputs ||= Ci::Input::Inputs.new(spec, args)
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
