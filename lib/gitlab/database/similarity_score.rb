# frozen_string_literal: true

module Gitlab
  module Database
    class SimilarityScore
      EMPTY_STRING = Arel.sql("''").freeze
      EXPRESSION_ON_INVALID_INPUT = Arel::Nodes::NamedFunction.new('CAST', [Arel.sql('0').as('integer')]).freeze
      DEFAULT_MULTIPLIER = 1
      DISPLAY_NAME = self.name.underscore.freeze

      # Adds a "magic" comment in the generated SQL expression in order to be able to tell if we're sorting by similarity.
      # Example: /* gitlab/database/similarity_score */ SIMILARITY(COALESCE...
      SIMILARITY_FUNCTION_CALL_WITH_ANNOTATION = "/* #{DISPLAY_NAME} */ SIMILARITY"

      # This method returns an Arel expression that can be used in an ActiveRecord query to order the resultset by similarity.
      #
      # Note: Calculating similarity score for large volume of records is inefficient. use SimilarityScore only for smaller
      # resultset which is already filtered by other conditions (< 10_000 records).
      #
      # ==== Parameters
      # * +search+ - [String] the user provided search string
      # * +rules+ - [{ column: COLUMN, multiplier: 1 }, { column: COLUMN_2, multiplier: 0.5 }] rules for the scoring.
      #   * +column+ - Arel column expression, example: Project.arel_table["name"]
      #   * +multiplier+ - Integer or Float to increase or decrease the score (optional, defaults to 1)
      #
      # ==== Use case
      #
      # We'd like to search for projects by path, name and description. We want to rank higher the path and name matches, since
      # it's more likely that the user was remembering the path or the name of the project.
      #
      # Rules:
      #   [
      #     { column: Project.arel_table['path'], multiplier: 1 },
      #     { column: Project.arel_table['name'], multiplier: 1 },
      #     { column: Project.arel_table['description'], multiplier: 0.5 }
      #   ]
      #
      # ==== Examples
      #
      #  Similarity calculation based on one column:
      #
      #  Gitlab::Database::SimilarityScore.build_expession(search: 'my input', rules: [{ column: Project.arel_table['name'] }])
      #
      #  Similarity calculation based on two column, where the second column has lower priority:
      #
      #  Gitlab::Database::SimilarityScore.build_expession(search: 'my input', rules: [
      #    { column: Project.arel_table['name'], multiplier: 1 },
      #    { column: Project.arel_table['description'], multiplier: 0.5 }
      #  ])
      #
      #  Integration with an ActiveRecord query:
      #
      #  table = Project.arel_table
      #
      #  order_expression = Gitlab::Database::SimilarityScore.build_expession(search: 'input', rules: [
      #    { column: table['name'], multiplier: 1 },
      #    { column: table['description'], multiplier: 0.5 }
      #  ])
      #
      #  Project.where("name LIKE ?", '%' + 'input' + '%').order(order_expression.desc)
      #
      #  The expression can be also used in SELECT:
      #
      #  results = Project.select(order_expression.as('similarity')).where("name LIKE ?", '%' + 'input' + '%').order(similarity: :desc)
      #  puts results.map(&:similarity)
      #
      def self.build_expression(search:, rules:)
        return EXPRESSION_ON_INVALID_INPUT if search.blank? || rules.empty?

        quoted_search = ApplicationRecord.connection.quote(search.to_s)

        first_expression, *expressions = rules.map do |rule|
          rule_to_arel(quoted_search, rule)
        end

        # (SIMILARITY ...) + (SIMILARITY ...)
        additions = expressions.inject(first_expression) do |expression1, expression2|
          Arel::Nodes::Addition.new(expression1, expression2)
        end

        score_as_numeric = Arel::Nodes::NamedFunction.new('CAST', [Arel::Nodes::Grouping.new(additions).as('numeric')])

        # Rounding the score to two decimals
        Arel::Nodes::NamedFunction.new('ROUND', [score_as_numeric, 2])
      end

      def self.order_by_similarity?(arel_query)
        arel_query.to_sql.include?(SIMILARITY_FUNCTION_CALL_WITH_ANNOTATION)
      end

      # (SIMILARITY(COALESCE(column, ''), 'search_string') * CAST(multiplier AS numeric))
      def self.rule_to_arel(search, rule)
        Arel::Nodes::Grouping.new(
          Arel::Nodes::Multiplication.new(
            similarity_function_call(search, column_expression(rule)),
            multiplier_expression(rule)
          )
        )
      end

      # COALESCE(column, '')
      def self.column_expression(rule)
        Arel::Nodes::NamedFunction.new('COALESCE', [rule.fetch(:column), EMPTY_STRING])
      end

      # SIMILARITY(COALESCE(column, ''), 'search_string')
      def self.similarity_function_call(search, column)
        Arel::Nodes::NamedFunction.new(SIMILARITY_FUNCTION_CALL_WITH_ANNOTATION, [column, Arel.sql(search)])
      end

      # CAST(multiplier AS numeric)
      def self.multiplier_expression(rule)
        quoted_multiplier = ApplicationRecord.connection.quote(rule.fetch(:multiplier, DEFAULT_MULTIPLIER).to_s)

        Arel::Nodes::NamedFunction.new('CAST', [Arel.sql(quoted_multiplier).as('numeric')])
      end

      private_class_method :rule_to_arel
      private_class_method :column_expression
      private_class_method :similarity_function_call
      private_class_method :multiplier_expression
    end
  end
end
