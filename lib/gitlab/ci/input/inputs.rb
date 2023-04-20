# frozen_string_literal: true

module Gitlab
  module Ci
    module Input
      ##
      # Inputs::Input class represents user-provided inputs, configured using `with:` keyword.
      #
      # Input arguments are only valid with an associated component's inputs specification from component's header.
      #
      class Inputs
        UnknownSpecArgumentError = Class.new(StandardError)

        ARGUMENTS = [
          Input::Arguments::Required, # Input argument is required
          Input::Arguments::Default,  # Input argument has a default value
          Input::Arguments::Options,  # Input argument that needs to be allowlisted
          Input::Arguments::Unknown   # Input argument has not been recognized
        ].freeze

        def initialize(spec, args)
          @spec = spec.to_h
          @args = args.to_h
          @inputs = []
          @errors = []

          validate!
          fabricate!
        end

        def errors
          @errors + @inputs.flat_map(&:errors)
        end

        def valid?
          errors.none?
        end

        def unknown
          @args.keys - @spec.keys
        end

        def count
          @inputs.count
        end

        def to_hash
          @inputs.inject({}) do |hash, argument|
            raise ArgumentError unless argument.valid?

            hash.merge(argument.to_hash)
          end
        end

        private

        def validate!
          @errors.push("unknown input arguments: #{unknown.inspect}") if unknown.any?
        end

        def fabricate!
          @spec.each do |key, spec|
            argument = ARGUMENTS.find { |klass| klass.matches?(spec) }

            raise UnknownSpecArgumentError if argument.nil?

            @inputs.push(argument.new(key, spec, @args[key]))
          end
        end
      end
    end
  end
end
