# frozen_string_literal: true

module UseSqlFunctionForPrimaryKeyLookups
  extend ActiveSupport::Concern

  class_methods do
    def find(*args)
      return super unless Feature.enabled?(:use_sql_functions_for_primary_key_lookups, Feature.current_request)
      return super unless args.one?
      return super if block_given? || primary_key.nil? || scope_attributes?

      return_array = false
      id = args.first

      if id.is_a?(Array)
        return super if id.many?

        return_array = true

        id = id.first
      end

      return super if id.nil? || (id.is_a?(String) && !id.number?)

      from_clause = "find_#{table_name}_by_id(?) #{quoted_table_name}"
      filter_empty_row = "#{quoted_table_name}.#{connection.quote_column_name(primary_key)} IS NOT NULL"
      query = from(from_clause).where(filter_empty_row).limit(1).to_sql
      # Using find_by_sql so we get query cache working
      record = find_by_sql([query, id]).first

      unless record
        message = "Couldn't find #{name} with '#{primary_key}'=#{id}"
        raise(ActiveRecord::RecordNotFound.new(message, name, primary_key, id))
      end

      return_array ? [record] : record
    end
  end
end
