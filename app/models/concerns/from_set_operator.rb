# frozen_string_literal: true

module FromSetOperator
  # Define a high level method to more easily work with the SQL set operations
  # of UNION, INTERSECT, and EXCEPT as defined by Gitlab::SQL::Union,
  # Gitlab::SQL::Intersect, and Gitlab::SQL::Except respectively.
  def define_set_operator(operator)
    method_name = 'from_' + operator.name.demodulize.downcase
    method_name = method_name.to_sym

    raise "Trying to redefine method '#{method(method_name)}'" if methods.include?(method_name)

    define_method(method_name) do |*members, remove_duplicates: true, remove_order: true, alias_as: table_name|
      members = flatten_ar_array(members)

      operator_sql =
        if members.any?
          operator.new(members, remove_duplicates: remove_duplicates, remove_order: remove_order).to_sql
        else
          where("1=0").to_sql
        end

      from(Arel.sql("(#{operator_sql}) #{alias_as}"))
    end

    # Array#flatten with ActiveRecord::Relation items will load the ActiveRecord::Relation.
    # Therefore we need to roll our own flatten method.
    unless method_defined?(:flatten_ar_array) # rubocop:disable Style/GuardClause
      define_method :flatten_ar_array do |ary|
        arrays = ary.dup
        result = []

        until arrays.empty?
          item = arrays.shift
          if item.is_a?(Array)
            arrays.concat(item.dup)
          else
            result.push(item)
          end
        end

        result
      end
      private :flatten_ar_array
    end
  end
end
