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
        return paginate_with_offset_headers(finder) if paginate_with_offset_headers?(finder)

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
        when Gitlab::Git::Finders::BranchesFinder
          true
        when TagsFinder
          true
        when ::Repositories::TreeFinder
          true
        when ::Repositories::CommitsFinder
          Feature.enabled?(:commits_keyset_pagination, project)
        end
      end

      def first_page?
        params[:page].blank? || params[:page].to_i == 1
      end

      def paginate_with_offset_headers?(finder)
        case finder
        when Gitlab::Git::Finders::BranchesFinder
          true
        when BranchesFinder
          first_page? && Feature.enabled?(:branch_list_keyset_pagination, project)
        when TagsFinder
          first_page? && params[:search].blank?
        when ::Repositories::TreeFinder
          first_page?
        end
      end

      # Paginates via Gitaly and builds offset-style headers manually.
      # The finder is expected to return only the records for the requested page.
      # For Gitlab::Git::Finders::BranchesFinder, it over-fetches from Gitaly
      # and slices internally; other finders return page 1 records directly.
      def paginate_with_offset_headers(finder)
        records = finder.execute(gitaly_pagination: true)
        build_offset_headers(finder)
        records
      end

      def build_offset_headers(finder)
        total = finder.total
        per_page = (params[:per_page].presence || Kaminari.config.default_per_page).to_i
        page = (params[:page].presence || 1).to_i
        without_counts = total.nil?

        total_pages = without_counts ? nil : (total / per_page.to_f).ceil
        next_page = if without_counts
                      finder.respond_to?(:next_cursor) && finder.next_cursor.present? ? page + 1 : nil
                    else
                      (page < total_pages ? page + 1 : nil)
                    end

        prev_page = page > 1 ? page - 1 : nil

        Gitlab::Pagination::OffsetHeaderBuilder.new(
          request_context: request_context, per_page: per_page, page: page,
          next_page: next_page, prev_page: prev_page,
          total: total, total_pages: total_pages
        ).execute(data_without_counts: without_counts)
      end

      def paginate_via_gitaly(finder)
        finder.execute(gitaly_pagination: true).tap do |records|
          apply_headers(records, finder.next_cursor)
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
