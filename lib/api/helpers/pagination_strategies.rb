# frozen_string_literal: true

module API
  module Helpers
    module PaginationStrategies
      def paginate_with_strategies(relation)
        paginator = paginator(relation)

        yield(paginator.paginate(relation)).tap do |records, _|
          paginator.finalize(records)
        end
      end

      def paginator(relation)
        return Gitlab::Pagination::OffsetPagination.new(self) unless keyset_pagination_enabled?

        request_context = Gitlab::Pagination::Keyset::RequestContext.new(self)

        unless Gitlab::Pagination::Keyset.available?(request_context, relation)
          return error!('Keyset pagination is not yet available for this type of request', 405)
        end

        Gitlab::Pagination::Keyset::Pager.new(request_context)
      end

      private

      def keyset_pagination_enabled?
        params[:pagination] == 'keyset' && Feature.enabled?(:api_keyset_pagination, default_enabled: true)
      end
    end
  end
end
