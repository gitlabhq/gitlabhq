module Gitlab
  module Database
    module DateTime
      # Find the first of the `end_time_attrs` that isn't `NULL`. Subtract from it
      # the first of the `start_time_attrs` that isn't NULL. `SELECT` the resulting interval
      # along with an alias specified by the `as` parameter.
      #
      # Note: For MySQL, the interval is returned in seconds.
      #       For PostgreSQL, the interval is returned as an INTERVAL type.
      def subtract_datetimes(query_so_far, end_time_attrs, start_time_attrs, as)
        diff_fn = subtract_datetimes_diff(query_so_far, end_time_attrs, start_time_attrs)

        query_so_far.project(diff_fn.as(as))
      end

      def subtract_datetimes_diff(query_so_far, end_time_attrs, start_time_attrs)
        if Gitlab::Database.postgresql?
          Arel::Nodes::Subtraction.new(
            Arel::Nodes::NamedFunction.new("COALESCE", Array.wrap(end_time_attrs)),
            Arel::Nodes::NamedFunction.new("COALESCE", Array.wrap(start_time_attrs)))
        elsif Gitlab::Database.mysql?
          Arel::Nodes::NamedFunction.new(
            "TIMESTAMPDIFF",
            [Arel.sql('second'),
             Arel::Nodes::NamedFunction.new("COALESCE", Array.wrap(start_time_attrs)),
             Arel::Nodes::NamedFunction.new("COALESCE", Array.wrap(end_time_attrs))])
        end
      end
    end
  end
end
