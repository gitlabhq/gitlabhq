# frozen_string_literal: true

module API
  module Helpers
    module PaginationStrategies
      # paginator_params are only currently supported with offset pagination
      def paginate_with_strategies(relation, request_scope = nil, paginator_params: {})
        paginator = paginator(relation, request_scope)

        result = if block_given?
                   yield(paginator.paginate(relation, **paginator_params))
                 else
                   paginator.paginate(relation, **paginator_params)
                 end

        result.tap do |records, _|
          paginator.finalize(records)
        end
      end

      def paginator(relation, request_scope = nil)
        return keyset_paginator(relation) if keyset_pagination_enabled?

        offset_paginator(relation, request_scope)
      end

      private

      def keyset_paginator(relation)
        if cursor_based_keyset_pagination_supported?(relation)
          request_context_class = Gitlab::Pagination::Keyset::CursorBasedRequestContext
          paginator_class = Gitlab::Pagination::Keyset::CursorPager
          availability_checker = Gitlab::Pagination::CursorBasedKeyset
        else
          request_context_class = Gitlab::Pagination::Keyset::RequestContext
          paginator_class = Gitlab::Pagination::Keyset::Pager
          availability_checker = Gitlab::Pagination::Keyset
        end

        request_context = request_context_class.new(self)

        unless availability_checker.available?(request_context, relation)
          return error!('Keyset pagination is not yet available for this type of request', 405)
        end

        paginator_class.new(request_context)
      end

      def offset_paginator(relation, request_scope)
        offset_limit = limit_for_scope(request_scope)
        if (Gitlab::Pagination::Keyset.available_for_type?(relation) ||
            cursor_based_keyset_pagination_supported?(relation)) &&
            cursor_based_keyset_pagination_enforced?(request_scope, relation) &&
            offset_limit_exceeded?(offset_limit)

          return error!("Offset pagination has a maximum allowed offset of #{offset_limit} " \
            "for requests that return objects of type #{relation.klass}. " \
            "Remaining records can be retrieved using keyset pagination.", 405)
        end

        Gitlab::Pagination::OffsetPagination.new(self)
      end

      def cursor_based_keyset_pagination_supported?(relation)
        Gitlab::Pagination::CursorBasedKeyset.available_for_type?(relation)
      end

      def cursor_based_keyset_pagination_enforced?(request_scope, relation)
        Gitlab::Pagination::CursorBasedKeyset.enforced_for_type?(request_scope, relation)
      end

      def keyset_pagination_enabled?
        params[:pagination] == 'keyset'
      end

      def limit_for_scope(scope)
        (scope || Plan.default).actual_limits.offset_pagination_limit
      end

      def offset_limit_exceeded?(offset_limit)
        offset_limit > 0 && params[:page] * params[:per_page] > offset_limit
      end
    end
  end
end
