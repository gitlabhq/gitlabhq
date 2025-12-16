# frozen_string_literal: true

class SanitizeAiCatalogItemDefinitions < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  class AiCatalogItemVersion < MigrationRecord
    self.table_name = 'ai_catalog_item_versions'

    include EachBatch
  end

  DANGEROUS_CHARS = Regexp.union(
    /[\p{Cc}&&[^\t\n\r]]/, # All control chars except tab, LF, CR
    /\u00AD/,              # Soft hyphen
    /\u200B/,              # ZWSP
    /[\u202A-\u202E]/,     # Bidi overrides
    /\u2060/,              # Word joiner
    /[\u2066-\u2069]/,     # Bidi isolates
    /\uFEFF/,              # BOM
    /[\uFFF9-\uFFFB]/,     # Annotations
    /\uFFFC/,              # Object replacement
    /[\u2062-\u2064]/,     # Invisible math operators
    /[\u{E0000}-\u{E01EF}]/, # Tag characters + Variation Selectors Supplement
    /[\u2028-\u2029]/ # Line/paragraph separators
  ).freeze

  def up
    AiCatalogItemVersion.reset_column_information

    AiCatalogItemVersion.each_batch(of: 100) do |relation|
      relation.each do |version|
        next if version.definition.blank?

        json_string = version.definition.to_json

        next unless json_string.match?(DANGEROUS_CHARS)

        sanitized_json = json_string.gsub(DANGEROUS_CHARS, '')
        begin
          new_definition = Gitlab::Json.parse(sanitized_json)
          version.update_column(:definition, new_definition)
        rescue JSON::ParserError => e
          # Log the error but continue with the migration
          Gitlab::AppLogger.warn(
            "Failed to parse sanitized JSON for AI catalog item version #{version.id}: #{e.message}"
          )
        end
      end
    end
  end

  def down
    # no-op
  end
end
