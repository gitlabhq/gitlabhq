# frozen_string_literal: true

module API
  module Helpers
    module Pagination
      def paginate(*args, **kwargs)
        Gitlab::Pagination::OffsetPagination.new(self).paginate(*args, **kwargs)
      end
    end
  end
end
