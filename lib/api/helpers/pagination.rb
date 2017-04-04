module API
  module Helpers
    module Pagination
      def paginate(relation)
        relation.page(params[:page]).per(params[:per_page]).tap do |data|
          add_pagination_headers(data)
        end
      end

      private

      def add_pagination_headers(paginated_data)
        header 'X-Total',       paginated_data.total_count.to_s
        header 'X-Total-Pages', paginated_data.total_pages.to_s
        header 'X-Per-Page',    paginated_data.limit_value.to_s
        header 'X-Page',        paginated_data.current_page.to_s
        header 'X-Next-Page',   paginated_data.next_page.to_s
        header 'X-Prev-Page',   paginated_data.prev_page.to_s
        header 'Link',          pagination_links(paginated_data)
      end

      def pagination_links(paginated_data)
        request_url = request.url.split('?').first
        request_params = params.clone
        request_params[:per_page] = paginated_data.limit_value

        links = []

        request_params[:page] = paginated_data.current_page - 1
        links << %(<#{request_url}?#{request_params.to_query}>; rel="prev") unless paginated_data.first_page?

        request_params[:page] = paginated_data.current_page + 1
        links << %(<#{request_url}?#{request_params.to_query}>; rel="next") unless paginated_data.last_page?

        request_params[:page] = 1
        links << %(<#{request_url}?#{request_params.to_query}>; rel="first")

        request_params[:page] = paginated_data.total_pages
        links << %(<#{request_url}?#{request_params.to_query}>; rel="last")

        links.join(', ')
      end
    end
  end
end
