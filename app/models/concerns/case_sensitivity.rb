# Concern for querying columns with specific case sensitivity handling.
module CaseSensitivity
  extend ActiveSupport::Concern

  module ClassMethods
    # Queries the given columns regardless of the casing used.
    #
    # Unlike other ActiveRecord methods this method only operates on a Hash.
    def iwhere(params)
      criteria   = self
      cast_lower = Gitlab::Database.postgresql?

      params.each do |key, value|
        column = ActiveRecord::Base.connection.quote_table_name(key)

        if cast_lower
          condition = "LOWER(#{column}) = LOWER(:value)"
        else
          condition = "#{column} = :value"
        end

        criteria = criteria.where(condition, value: value)
      end

      criteria
    end
  end
end
