# frozen_string_literal: true

# This patch adds support for AS MATERIALIZED in Arel, see Gitlab::Database::AsWithMaterialized for more info
module Arel
  module Visitors
    class Arel::Visitors::PostgreSQL
      def visit_Gitlab_Database_AsWithMaterialized(obj, collector) # rubocop:disable Naming/MethodName
        collector = visit obj.left, collector
        collector << " AS "
        visit obj.right, collector
      end
    end
  end
end
