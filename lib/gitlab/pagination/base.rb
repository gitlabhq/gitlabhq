# frozen_string_literal: true

module Gitlab
  module Pagination
    class Base
      def paginate(relation)
        raise NotImplementedError
      end

      def finalize(records)
        # Optional: Called with the actual set of records
      end
    end
  end
end
