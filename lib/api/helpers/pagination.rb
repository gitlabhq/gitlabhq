# frozen_string_literal: true

module API
  module Helpers
    module Pagination
      # This returns an ActiveRecord relation
      def paginate(relation)
        Gitlab::Pagination::OffsetPagination.new(self).paginate(relation)
      end

      # This applies pagination and executes the query
      # It always returns an array instead of an ActiveRecord relation
      def paginate_and_retrieve!(relation)
        offset_or_keyset_pagination(relation).to_a
      end

      private

      def offset_or_keyset_pagination(relation)
        return paginate(relation) unless keyset_pagination_enabled?

        request_context = Gitlab::Pagination::Keyset::RequestContext.new(self)

        unless Gitlab::Pagination::Keyset.available?(request_context, relation)
          return error!('Keyset pagination is not yet available for this type of request', 405)
        end

        Gitlab::Pagination::Keyset.paginate(request_context, relation)
      end

      def keyset_pagination_enabled?
        params[:pagination] == 'keyset' && Feature.enabled?(:api_keyset_pagination, default_enabled: true)
      end
    end
  end
end
