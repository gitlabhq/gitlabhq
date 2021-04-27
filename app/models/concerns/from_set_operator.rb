# frozen_string_literal: true

module FromSetOperator
  # Define a high level method to more easily work with the SQL set operations
  # of UNION, INTERSECT, and EXCEPT as defined by Gitlab::SQL::Union,
  # Gitlab::SQL::Intersect, and Gitlab::SQL::Except respectively.
  def define_set_operator(operator)
    method_name = 'from_' + operator.name.demodulize.downcase
    method_name = method_name.to_sym

    raise "Trying to redefine method '#{method(method_name)}'" if methods.include?(method_name)

    define_method(method_name) do |members, remove_duplicates: true, remove_order: true, alias_as: table_name|
      operator_sql = operator.new(members, remove_duplicates: remove_duplicates, remove_order: remove_order).to_sql

      from(Arel.sql("(#{operator_sql}) #{alias_as}"))
    end
  end
end
