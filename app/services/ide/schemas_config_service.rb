# frozen_string_literal: true

module Ide
  class SchemasConfigService < ::Ide::BaseConfigService
    PREDEFINED_SCHEMAS = [{
      uri: 'https://json.schemastore.org/gitlab-ci',
      match: ['*.gitlab-ci.yml']
    }].freeze

    def execute
      schema = predefined_schema_for(params[:filename]) || {}
      success(schema: schema)
    rescue StandardError => e
      error(e.message)
    end

    private

    def find_schema(filename, schemas)
      match_flags = ::File::FNM_DOTMATCH | ::File::FNM_PATHNAME

      schemas.each do |schema|
        match = schema[:match].any? { |pattern| ::File.fnmatch?(pattern, filename, match_flags) }

        return Gitlab::Json.parse(get_cached(schema[:uri])) if match
      end

      nil
    end

    def predefined_schema_for(filename)
      find_schema(filename, predefined_schemas)
    end

    def predefined_schemas
      return PREDEFINED_SCHEMAS if Feature.enabled?(:schema_linting)

      []
    end

    def get_cached(url)
      Rails.cache.fetch("services:ide:schema:#{url}", expires_in: 1.day) do
        Gitlab::HTTP.get(url).body
      end
    end
  end
end

Ide::SchemasConfigService.prepend_mod_with('Ide::SchemasConfigService')
