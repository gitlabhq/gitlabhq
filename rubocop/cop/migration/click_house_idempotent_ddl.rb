# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # ClickHouse migrations have no `create_table`/`drop_table` DSL, only raw SQL.
      # A migration that fails halfway gets retried, so its DDL has to be idempotent.
      #
      # `CREATE TABLE`, `CREATE VIEW`, `CREATE MATERIALIZED VIEW` and `CREATE DICTIONARY`
      # need `IF NOT EXISTS`; `DROP TABLE`, `DROP VIEW` and `DROP DICTIONARY` need `IF EXISTS`.
      #
      # @example
      #   # bad
      #   execute <<~SQL
      #     CREATE TABLE my_table (id Int64) ENGINE = MergeTree
      #   SQL
      #   execute 'DROP VIEW my_view'
      #   execute 'DROP DICTIONARY my_dict'
      #
      #   # good
      #   execute <<~SQL
      #     CREATE TABLE IF NOT EXISTS my_table (id Int64) ENGINE = MergeTree
      #   SQL
      #   execute 'DROP VIEW IF EXISTS my_view'
      #   execute 'DROP DICTIONARY IF EXISTS my_dict'
      class ClickHouseIdempotentDdl < RuboCop::Cop::Base
        extend AutoCorrector
        include MigrationHelpers

        MSG = 'ClickHouse migrations must be idempotent. Use `%{statement} %{guard}`.'

        CREATE_GUARD = 'IF NOT EXISTS'
        DROP_GUARD = 'IF EXISTS'

        DDL_PATTERN = /
          \b(?<statement>
            CREATE\s+(?:MATERIALIZED\s+VIEW|VIEW|TABLE|DICTIONARY)
            |
            DROP\s+(?:TABLE|VIEW|DICTIONARY)
          )\b
          (?:\s+(?<guard>IF\s+(?:NOT\s+)?EXISTS)\b)?
        /xi

        def on_str(node)
          # Config `Include:` is not honored when RuboCop runs from a nested config root
          # such as `gems/`, so scope on the path here too.
          return unless in_click_house_migration?(node)
          # Parts of a heredoc or interpolated string are covered by the parent node.
          return if node.parent&.dstr_type?

          range = node.heredoc? ? node.loc.heredoc_body : node.source_range

          range.source.scan(DDL_PATTERN) do
            match = Regexp.last_match
            statement = squish(match[:statement])
            guard = guard_for(statement)
            next if squish(match[:guard]) == guard

            offense = locate(range, match)

            add_offense(offense, message: format(MSG, statement: statement, guard: guard)) do |corrector|
              corrector.replace(offense, "#{statement} #{guard}")
            end
          end
        end
        alias_method :on_dstr, :on_str

        private

        def guard_for(statement)
          statement.start_with?('DROP') ? DROP_GUARD : CREATE_GUARD
        end

        def squish(text)
          text.to_s.upcase.gsub(/\s+/, ' ')
        end

        # Narrows `range` down to just the matched statement, so the offense points at the
        # SQL line rather than at the heredoc marker.
        def locate(range, match)
          range.adjust(begin_pos: match.begin(0), end_pos: match.end(0) - range.length)
        end
      end
    end
  end
end
