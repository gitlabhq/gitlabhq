# frozen_string_literal: true

module Gitlab
  module SQL
    module Glob
      extend self

      # Convert a simple glob pattern with wildcard (*) to SQL LIKE pattern
      # with SQL expression
      def to_like(pattern)
        <<~SQL
          REPLACE(REPLACE(REPLACE(#{pattern},
                                  #{q('%')}, #{q('\\%')}),
                          #{q('_')}, #{q('\\_')}),
                  #{q('*')}, #{q('%')})
        SQL
      end

      def q(string)
        ApplicationRecord.connection.quote(string)
      end
    end
  end
end
