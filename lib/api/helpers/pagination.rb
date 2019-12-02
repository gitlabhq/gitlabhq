# frozen_string_literal: true

module API
  module Helpers
    module Pagination
      def paginate(relation)
        ::Gitlab::Pagination::OffsetPagination.new(self).paginate(relation)
      end
    end
  end
end
