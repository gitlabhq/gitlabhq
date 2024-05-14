# frozen_string_literal: true

module Types
  class RangeInputType < BaseInputObject
    def self.[](type, closed = true)
      @subtypes ||= {}

      @subtypes[[type, closed]] ||= Class.new(self) do
        argument :start, type,
          required: closed,
          description: 'Start of the range.'

        argument :end, type,
          required: closed,
          description: 'End of the range.'
      end
    end

    def prepare
      if self[:end] && self[:start] && self[:end] < self[:start]
        raise ::Gitlab::Graphql::Errors::ArgumentError, 'start must be before end'
      end

      super
    end
  end
end
