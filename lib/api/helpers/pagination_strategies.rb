# frozen_string_literal: true

module API
  module Helpers
    module PaginationStrategies
      def paginate_with_strategies(relation, request_scope)
        paginator = paginator(relation, request_scope)

        yield(paginator.paginate(relation)).tap do |records, _|
          paginator.finalize(records)
        end
      end

      def paginator(relation, request_scope = nil)
        return keyset_paginator(relation) if keyset_pagination_enabled?

        offset_paginator(relation, request_scope)
      end

      private

      def keyset_paginator(relation)
        request_context = Gitlab::Pagination::Keyset::RequestContext.new(self)
        unless Gitlab::Pagination::Keyset.available?(request_context, relation)
          return error!('Keyset pagination is not yet available for this type of request', 405)
        end

        Gitlab::Pagination::Keyset::Pager.new(request_context)
      end

      def offset_paginator(relation, request_scope)
        offset_limit = limit_for_scope(request_scope)
        if Gitlab::Pagination::Keyset.available_for_type?(relation) && offset_limit_exceeded?(offset_limit)
          return error!("Offset pagination has a maximum allowed offset of #{offset_limit} " \
            "for requests that return objects of type #{relation.klass}. " \
            "Remaining records can be retrieved using keyset pagination.", 405)
        end

        Gitlab::Pagination::OffsetPagination.new(self)
      end

      def keyset_pagination_enabled?
        params[:pagination] == 'keyset'
      end

      def limit_for_scope(scope)
        (scope || Plan.default).actual_limits.offset_pagination_limit
      end

      def offset_limit_exceeded?(offset_limit)
        offset_limit.positive? && params[:page] * params[:per_page] > offset_limit
      end
    end
  end
end
