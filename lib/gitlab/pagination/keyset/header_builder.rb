# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      class HeaderBuilder
        attr_reader :request_context

        delegate :params, :header, :request, to: :request_context

        def initialize(request_context)
          @request_context = request_context
        end

        def add_next_page_header(query_params)
          link = next_page_link(page_href(query_params))
          header('Link', link)
        end

        private

        def next_page_link(href)
          %(<#{href}>; rel="next")
        end

        def page_href(query_params)
          base_request_uri.tap do |uri|
            uri.query = updated_params(query_params).to_query
          end.to_s
        end

        def base_request_uri
          @base_request_uri ||= URI.parse(request.url).tap do |uri|
            uri.host = Gitlab.config.gitlab.host
            uri.port = Gitlab.config.gitlab.port
          end
        end

        def updated_params(query_params)
          params.merge(query_params)
        end
      end
    end
  end
end
