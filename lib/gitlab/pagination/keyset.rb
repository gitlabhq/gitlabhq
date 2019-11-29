# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      def self.paginate(request_context, relation)
        Gitlab::Pagination::Keyset::Pager.new(request_context).paginate(relation)
      end

      def self.available?(request_context, relation)
        order_by = request_context.page.order_by

        # This is only available for Project and order-by id (asc/desc)
        return false unless relation.klass == Project
        return false unless order_by.size == 1 && order_by[:id]

        true
      end
    end
  end
end
