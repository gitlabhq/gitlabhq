# frozen_string_literal: true

module API
  module Helpers
    module Pagination
      def paginate(*args)
        Gitlab::Pagination::OffsetPagination.new(self).paginate(*args)
      end
    end
  end
end
