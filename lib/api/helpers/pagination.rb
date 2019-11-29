# frozen_string_literal: true

module API
  module Helpers
    module Pagination
      def paginate(relation)
        return Gitlab::Pagination::OffsetPagination.new(self).paginate(relation) unless keyset_pagination_enabled?

        request_context = Gitlab::Pagination::Keyset::RequestContext.new(self)

        unless Gitlab::Pagination::Keyset.available?(request_context, relation)
          return error!('Keyset pagination is not yet available for this type of request', 501)
        end

        Gitlab::Pagination::Keyset.paginate(request_context, relation)
      end

      private

      def keyset_pagination_enabled?
        params[:pagination] == 'keyset' && Feature.enabled?(:api_keyset_pagination)
      end
    end
  end
end
