# frozen_string_literal: true

module ClickHouse
  module TableSettingsNormalizer
    def self.run(statement, version)
      if statement.exclude?("deduplicate_merge_projection_mode = 'rebuild'") &&
          statement.include?("MODIFY SETTING deduplicate_merge_projection_mode")
        return statement
      end

      return statement if Gem::Version.new(version) >= Gem::Version.new("24.8")

      statement
        .gsub(", deduplicate_merge_projection_mode = 'rebuild'", '')
        .gsub("deduplicate_merge_projection_mode = 'rebuild', ", '')
        .gsub("SETTING deduplicate_merge_projection_mode = 'rebuild'", '')
    end
  end
end
