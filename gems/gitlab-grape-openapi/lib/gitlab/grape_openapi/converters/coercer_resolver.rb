# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      module CoercerResolver
        def coercer_mapping_for(validations)
          coercer_method = extract_coercer_method(validations)
          return unless coercer_method # Validation doesn't use `coerce_with`
          return if inline_proc?(coercer_method) # Inline Procs shouldn't need a coercer method

          coercer_name = resolve_coercer_name(coercer_method)
          config = Gitlab::GrapeOpenapi.configuration
          mapping = config.coercer_mappings.find { |pattern, _mapping| coercer_name == pattern }&.last
          return mapping if mapping

          raise GenerationError,
            "No OpenAPI schema mapping found for coercer '#{coercer_name}'. " \
              "Add an entry for '#{coercer_name}' to coercer_mappings in " \
              "config/initializers/gitlab_grape_openapi.rb, or use an inline lambda instead."
        end

        def build_coerced_schema(mapping)
          schema = {}
          schema[:type] = mapping[:type] if mapping[:type]
          schema[:items] = { type: mapping[:items_type] } if mapping[:items_type]
          schema[:format] = mapping[:format] if mapping[:format]
          schema[:additional_properties] = mapping[:additional_properties] if mapping[:additional_properties]

          schema
        end

        private

        def extract_coercer_method(validations)
          return unless validations

          coerce_validation = validations.find do |v|
            v[:validator_class] == Grape::Validations::Validators::CoerceValidator
          end
          return unless coerce_validation

          coerce_validation.dig(:options, :method)
        end

        def inline_proc?(coercer_method)
          return false unless coercer_method.is_a?(Proc)

          source_file, _line = coercer_method.source_location
          return true unless source_file

          source_file.exclude?('/validations/types/')
        end

        def resolve_coercer_name(coercer_method)
          return coercer_name_from_source_location(coercer_method) if coercer_method.is_a?(Proc)

          coercer_method.name.to_s
        end

        def coercer_name_from_source_location(coercer_method)
          source_file, _line = coercer_method.source_location
          return coercer_method.to_s unless source_file

          camelize(File.basename(source_file, '.rb'))
        end

        def camelize(str)
          str.split('_').map(&:capitalize).join
        end
      end
    end
  end
end
