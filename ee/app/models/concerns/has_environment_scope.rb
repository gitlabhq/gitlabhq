module HasEnvironmentScope
  extend ActiveSupport::Concern

  prepended do
    validates(
      :environment_scope,
      presence: true,
      format: { with: ::Gitlab::Regex.environment_scope_regex,
                message: ::Gitlab::Regex.environment_scope_regex_message }
    )

    scope :on_environment, -> (environment_name) do
      where = <<~SQL
        environment_scope IN (:wildcard, :environment_name) OR
          :environment_name LIKE
            #{::Gitlab::SQL::Glob.to_like('environment_scope')}
      SQL

      order = <<~SQL
        CASE environment_scope
          WHEN %{wildcard} THEN 0
          WHEN %{environment_name} THEN 2
          ELSE 1
        END
      SQL

      values = {
        wildcard: '*',
        environment_name: environment_name
      }

      quoted_values = values.transform_values do |value|
        # Note that the connection could be
        # Gitlab::Database::LoadBalancing::ConnectionProxy
        # which supports `quote` via `method_missing`
        ActiveRecord::Base.connection.quote(value)
      end

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
      where(where, values)
        .order(order % quoted_values) # `order` cannot escape for us!
    end
  end

  def environment_scope=(new_environment_scope)
    super(new_environment_scope.to_s.strip)
  end
end
