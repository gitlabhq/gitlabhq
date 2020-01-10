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

      private

      def per_page
        @per_page ||= params[:per_page]
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
    end
  end
end
