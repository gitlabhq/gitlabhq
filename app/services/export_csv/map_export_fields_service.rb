# frozen_string_literal: true

module ExportCsv
  class MapExportFieldsService < BaseService
    attr_reader :fields, :data

    def initialize(fields, data)
      @fields = fields
      @data = data
    end

    def execute
      return data if fields.empty?

      selected_fields_to_hash
    end

    def invalid_fields
      fields.reject { |field| permitted_field?(field) }
    end

    private

    def selected_fields_to_hash
      data.select { |key| requested_field?(key) }
    end

    def requested_field?(field)
      field.downcase.in?(fields.map(&:downcase))
    end

    def permitted_field?(field)
      field.downcase.in?(keys.map(&:downcase))
    end

    def keys
      data.keys
    end
  end
end
