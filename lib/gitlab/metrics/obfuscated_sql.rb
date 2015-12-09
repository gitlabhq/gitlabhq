module Gitlab
  module Metrics
    # Class for producing SQL queries with sensitive data stripped out.
    class ObfuscatedSQL
      REPLACEMENT = /
        \d+(\.\d+)?      # integers, floats
        | '.+?'          # single quoted strings
        | \/.+?(?<!\\)\/ # regexps (including escaped slashes)
      /x

      MYSQL_REPLACEMENTS = /
        ".+?" # double quoted strings
      /x

      # Regex to replace consecutive placeholders with a single one indicating
      # the length. This can be useful when a "IN" statement uses thousands of
      # IDs (storing this would just be a waste of space).
      CONSECUTIVE = /(\?(\s*,\s*)?){2,}/

      # sql - The raw SQL query as a String.
      def initialize(sql)
        @sql = sql
      end

      # Returns a new, obfuscated SQL query.
      def to_s
        regex = REPLACEMENT

        if Gitlab::Database.mysql?
          regex = Regexp.union(regex, MYSQL_REPLACEMENTS)
        end

        @sql.gsub(regex, '?').gsub(CONSECUTIVE) do |match|
          "#{match.count(',') + 1} values"
        end
      end
    end
  end
end
