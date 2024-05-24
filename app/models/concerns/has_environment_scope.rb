# frozen_string_literal: true

module HasEnvironmentScope
  extend ActiveSupport::Concern

  prepended do
    validates(
      :environment_scope,
      presence: true,
      format: { with: ::Gitlab::Regex.environment_scope_regex,
                message: ::Gitlab::Regex.environment_scope_regex_message }
    )

    ##
    # Select rows which have a scope that matches the given environment name.
    # Rows are ordered by relevance, by default. The most relevant row is
    # placed at the end of a list.
    #
    # options:
    #   - relevant_only: (boolean)
    #     You can get the most relevant row only. Other rows are not be
    #     selected even if its scope matches the environment name.
    #     This is equivalent to using `#last` from SQL standpoint.
    #
    scope :on_environment, ->(environment_name, relevant_only: false) do
      order_direction = relevant_only ? 'DESC' : 'ASC'

      where = <<~SQL
        environment_scope IN (:wildcard, :environment_name) OR
          :environment_name LIKE
            #{::Gitlab::SQL::Glob.to_like('environment_scope')}
      SQL

      order = <<~SQL
        CASE environment_scope
          WHEN :wildcard THEN 0
          WHEN :environment_name THEN 2
          ELSE 1
        END #{order_direction}
      SQL

      values = {
        wildcard: '*',
        environment_name: environment_name
      }

      sanitized_order_sql = sanitize_sql_array([order, values])

      # The query is trying to find variables with scopes matching the
      # current environment name. Suppose the environment name is
      # 'review/app', and we have variables with environment scopes like:
      # * variable A: review
      # * variable B: review/app
      # * variable C: review/*
      # * variable D: *
      # And the query should find variable B, C, and D, because it would
      # try to convert the scope into a LIKE pattern for each variable:
      # * A: review
      # * B: review/app
      # * C: review/%
      # * D: %
      # Note that we'll match % and _ literally therefore we'll escape them.
      # In this case, B, C, and D would match. We also want to prioritize
      # the exact matched name, and put * last, and everything else in the
      # middle. So the order should be: D < C < B
      relation = where(where, values)
        .order(Arel.sql(sanitized_order_sql)) # `order` cannot escape for us!

      relation = relation.limit(1) if relevant_only

      relation
    end

    scope :for_environment, ->(environment) do
      if environment
        on_environment(environment)
      else
        where(environment_scope: '*')
      end
    end
  end

  def environment_scope=(new_environment_scope)
    super(new_environment_scope.to_s.strip)
  end
end
