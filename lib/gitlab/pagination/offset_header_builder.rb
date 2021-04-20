# frozen_string_literal: true

module Gitlab
  module Pagination
    class OffsetHeaderBuilder
      attr_reader :request_context, :per_page, :page, :next_page, :prev_page, :total, :total_pages

      delegate :request, to: :request_context

      def initialize(request_context:, per_page:, page:, next_page:, prev_page: nil, total: nil, total_pages: nil, params: nil)
        @request_context = request_context
        @per_page = per_page
        @page = page
        @next_page = next_page
        @prev_page = prev_page
        @total = total
        @total_pages = total_pages
        @params = params
      end

      def execute(exclude_total_headers: false, data_without_counts: false)
        header 'X-Per-Page',    per_page.to_s
        header 'X-Page',        page.to_s
        header 'X-Next-Page',   next_page.to_s
        header 'X-Prev-Page',   prev_page.to_s
        header 'Link',          pagination_links(data_without_counts)

        return if exclude_total_headers || data_without_counts

        header 'X-Total',       total.to_s
        header 'X-Total-Pages', total_pages.to_s
      end

      private

      def pagination_links(data_without_counts)
        [].tap do |links|
          links << %(<#{page_href(page: prev_page)}>; rel="prev") if prev_page
          links << %(<#{page_href(page: next_page)}>; rel="next") if next_page
          links << %(<#{page_href(page: 1)}>; rel="first")

          links << %(<#{page_href(page: total_pages)}>; rel="last") unless data_without_counts
        end.join(', ')
      end

      def base_request_uri
        @base_request_uri ||= URI.parse(request.url).tap do |uri|
          uri.host = Gitlab.config.gitlab.host
          uri.port = Gitlab.config.gitlab.port
        end
      end

      def build_page_url(query_params:)
        base_request_uri.tap do |uri|
          uri.query = query_params
        end.to_s
      end

      def page_href(next_page_params = {})
        query_params = params.merge(**next_page_params, per_page: per_page).to_query

        build_page_url(query_params: query_params)
      end

      def params
        @params || request_context.params
      end

      def header(name, value)
        if request_context.respond_to?(:header)
          # For Grape API
          request_context.header(name, value)
        else
          # For rails controllers
          request_context.response.headers[name] = value
        end
      end
    end
  end
end
