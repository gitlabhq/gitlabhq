# frozen_string_literal: true

module Types
  class RangeInputType < BaseInputObject
    def self.[](type, closed = true)
      @subtypes ||= {}

      @subtypes[[type, closed]] ||= Class.new(self) do
        argument :start, type,
                 required: closed,
                 description: 'The start of the range.'

        argument :end, type,
                 required: closed,
                 description: 'The end of the range.'
      end
    end

    def prepare
      if self[:end] && self[:start] && self[:end] < self[:start]
        raise ::Gitlab::Graphql::Errors::ArgumentError, 'start must be before end'
      end

      to_h
    end
  end
end
