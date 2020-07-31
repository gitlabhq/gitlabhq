# frozen_string_literal: true

module Gitlab
  module Pagination
    class GitalyKeysetPager
      attr_reader :request_context, :project
      delegate :params, to: :request_context

      def initialize(request_context, project)
        @request_context = request_context
        @project = project
      end

      # It is expected that the given finder will respond to `execute` method with `gitaly_pagination: true` option
      # and supports pagination via gitaly.
      def paginate(finder)
        return paginate_via_gitaly(finder) if keyset_pagination_enabled?

        branches = ::Kaminari.paginate_array(finder.execute)
        Gitlab::Pagination::OffsetPagination
          .new(request_context)
          .paginate(branches)
      end

      private

      def keyset_pagination_enabled?
        Feature.enabled?(:branch_list_keyset_pagination, project) && params[:pagination] == 'keyset'
      end

      def paginate_via_gitaly(finder)
        finder.execute(gitaly_pagination: true).tap do |records|
          apply_headers(records)
        end
      end

      def apply_headers(records)
        if records.count == params[:per_page]
          Gitlab::Pagination::Keyset::HeaderBuilder
            .new(request_context)
            .add_next_page_header(
              query_params_for(records.last)
            )
        end
      end

      def query_params_for(record)
        # NOTE: page_token is name for now, but it could be dynamic if we have other gitaly finders
        # that is based on something other than name
        { page_token: record.name }
      end
    end
  end
end
