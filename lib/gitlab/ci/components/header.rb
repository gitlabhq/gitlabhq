# frozen_string_literal: true

module Gitlab
  module Ci
    module Components
      ##
      # Components::Header class represents full component specification that is being prepended as first YAML document
      # in the CI Component file.
      #
      class Header
        attr_reader :errors

        def initialize(header)
          @header = header
          @errors = []
        end

        def empty?
          inputs_spec.to_h.empty?
        end

        def inputs(args)
          @input ||= Ci::Input::Inputs.new(inputs_spec, args)
        end

        def context(args)
          inputs(args).then do |input|
            raise ArgumentError unless input.valid?

            Ci::Interpolation::Context.new({ inputs: input.to_hash })
          end
        end

        private

        def inputs_spec
          @header.dig(:spec, :inputs)
        end
      end
    end
  end
end
