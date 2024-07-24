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

      # It is expected that the given finder will respond to `execute` method with `gitaly_pagination:` option
      # and supports pagination via gitaly.
      def paginate(finder)
        return finder.execute(gitaly_pagination: false) if no_pagination?(finder)

        return paginate_via_gitaly(finder) if keyset_pagination_enabled?(finder)
        return paginate_first_page_via_gitaly(finder) if paginate_first_page?(finder)

        records = ::Kaminari.paginate_array(finder.execute)
        Gitlab::Pagination::OffsetPagination
          .new(request_context)
          .paginate(records)
      end

      private

      def no_pagination?(finder)
        params[:pagination] == 'none' && finder.is_a?(::Repositories::TreeFinder)
      end

      def keyset_pagination_enabled?(finder)
        return false unless params[:pagination] == "keyset"

        case finder
        when BranchesFinder
          Feature.enabled?(:branch_list_keyset_pagination, project)
        when TagsFinder
          true
        when ::Repositories::TreeFinder
          true
        end
      end

      def paginate_first_page?(finder)
        return false unless params[:page].blank? || params[:page].to_i == 1

        case finder
        when BranchesFinder
          Feature.enabled?(:branch_list_keyset_pagination, project)
        when TagsFinder
          true
        when ::Repositories::TreeFinder
          true
        end
      end

      def paginate_via_gitaly(finder)
        finder.execute(gitaly_pagination: true).tap do |records|
          apply_headers(records, finder.next_cursor)
        end
      end

      # When first page is requested, we paginate the data via Gitaly
      # Headers are added to immitate offset pagination, while it is the default option
      def paginate_first_page_via_gitaly(finder)
        finder.execute(gitaly_pagination: true).tap do |records|
          total = finder.total
          per_page = params[:per_page].presence || Kaminari.config.default_per_page
          total_pages = (total / per_page.to_f).ceil
          next_page = total_pages > 1 ? 2 : nil

          Gitlab::Pagination::OffsetHeaderBuilder.new(
            request_context: request_context, per_page: per_page, page: 1, next_page: next_page,
            total: total, total_pages: total_pages
          ).execute
        end
      end

      def apply_headers(records, next_cursor)
        if records.count == params[:per_page] && next_cursor.present?
          Gitlab::Pagination::Keyset::HeaderBuilder
            .new(request_context)
            .add_next_page_header(
              query_params_for(next_cursor)
            )
        end
      end

      def query_params_for(next_cursor)
        { page_token: next_cursor }
      end
    end
  end
end
