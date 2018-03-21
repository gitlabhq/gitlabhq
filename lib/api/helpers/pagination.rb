module API
  module Helpers
    module Pagination
      def paginate(relation)
        relation = add_default_order(relation)

        relation.page(params[:page]).per(params[:per_page]).tap do |data|
          add_pagination_headers(data)
        end
      end

      private

      def add_pagination_headers(paginated_data)
        header 'X-Per-Page',    paginated_data.limit_value.to_s
        header 'X-Page',        paginated_data.current_page.to_s
        header 'X-Next-Page',   paginated_data.next_page.to_s
        header 'X-Prev-Page',   paginated_data.prev_page.to_s
        header 'Link',          pagination_links(paginated_data)

        return if data_without_counts?(paginated_data)

        header 'X-Total',       paginated_data.total_count.to_s
        header 'X-Total-Pages', total_pages(paginated_data).to_s
      end

      def pagination_links(paginated_data)
        request_url = request.url.split('?').first
        request_params = params.clone
        request_params[:per_page] = paginated_data.limit_value

        links = []

        request_params[:page] = paginated_data.prev_page
        links << %(<#{request_url}?#{request_params.to_query}>; rel="prev") if request_params[:page]

        request_params[:page] = paginated_data.next_page
        links << %(<#{request_url}?#{request_params.to_query}>; rel="next") if request_params[:page]

        request_params[:page] = 1
        links << %(<#{request_url}?#{request_params.to_query}>; rel="first")

        unless data_without_counts?(paginated_data)
          request_params[:page] = total_pages(paginated_data)
          links << %(<#{request_url}?#{request_params.to_query}>; rel="last")
        end

        links.join(', ')
      end

      def total_pages(paginated_data)
        # Ensure there is in total at least 1 page
        [paginated_data.total_pages, 1].max
      end

      def add_default_order(relation)
        if relation.is_a?(ActiveRecord::Relation) && relation.order_values.empty?
          relation = relation.order(:id)
        end

        relation
      end

      def data_without_counts?(paginated_data)
        paginated_data.is_a?(Kaminari::PaginatableWithoutCount)
      end
    end
  end
end
