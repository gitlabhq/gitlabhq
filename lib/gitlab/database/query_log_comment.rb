# frozen_string_literal: true

module Gitlab
  module Database
    # Builds SQL that reads ActiveRecord::QueryLogs tags from the comment that
    # production prepends to queries (see config/initializers/query_logs.rb),
    # for example in pg_stat_activity.query.
    #
    # Tags are looked up by key rather than by position: Rails 8 sorts them by
    # name, while Rails 7.2 emits them in the order configured in
    # Gitlab::QueryLogs.tags.
    module QueryLogComment
      # Each value pattern is a bounded character class, so no free text from
      # another session's SQL can be extracted.
      TAG_VALUE_PATTERNS = {
        application: '\w+',
        endpoint_id: '[\w/\-\.:#\s]+',
        db_config_database: '\w+'
      }.freeze

      # Returns a SQL expression that evaluates to the value of a tag in the
      # comment leading the query, or NULL when there is no such tag.
      #
      # split_part stops at the end of the first comment, so tags are never
      # read from the statement body or from a later comment.
      #
      # @param column [String] SQL expression holding the query text
      # @param tag [Symbol] a key of {TAG_VALUE_PATTERNS}
      # @return [String] SQL expression
      def self.tag_sql(column, tag)
        value_pattern = TAG_VALUE_PATTERNS.fetch(tag)

        "substring(split_part(#{column}, '*/', 1) from '^\\s*/\\*(?:.*,)?#{tag}:(#{value_pattern})')"
      end
    end
  end
end
