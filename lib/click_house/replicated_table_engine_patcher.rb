# frozen_string_literal: true

module ClickHouse
  module ReplicatedTableEnginePatcher
    def self.patch_replicated(statement)
      statement.gsub(/(Engine\s*=\s*)(\w*MergeTree)\b/i, '\1Replicated\2')
    end

    def self.unpatch_replicated(statement)
      statement.split("\n").map do |line|
        # Remove the "Replicated" prefix.
        # Remove the first 2 arguments: keeper path and replica name
        # Example:
        # ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}', updated_at, deleted)
        # Becomes:
        # ENGINE = ReplacingMergeTree(updated_at, deleted)
        line.gsub(
          /\bENGINE\s*=\s*Replicated(\w*?MergeTree)\s*\(\s*[^,]+,\s*[^,]+(?:,\s*([^)]*))?\)/i
        ) { "ENGINE = #{Regexp.last_match(1)}#{Regexp.last_match(2) ? "(#{Regexp.last_match(2)})" : ''}" }
      end.join("\n")
    end
  end
end
