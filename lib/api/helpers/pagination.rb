module API
  module Helpers
    module Pagination
      def paginate(relation)
        strategy = if params[:pagination] == 'keyset' && Feature.enabled?('api_keyset_pagination')
                     KeysetPaginationStrategy
                   else
                     DefaultPaginationStrategy
                   end

        strategy.new(self).paginate(relation)
      end

      class KeysetPaginationInfo
        attr_reader :relation, :request_context

        def initialize(relation, request_context)
          # This is because it's rather complex to support multiple values with possibly different sort directions
          # (and we don't need this in the API)
          if relation.order_values.size > 1
            raise "Pagination only supports ordering by a single column." \
              "The following columns were given: #{relation.order_values.map { |v| v.expr.name }}"
          end

          @relation = relation
          @request_context = request_context
        end

        def fields
          keys.zip(values).reject { |_, v| v.nil? }.to_h
        end

        def column_for_order_by(relation)
          relation.order_values.first&.expr&.name
        end

        # Sort direction (`:asc` or `:desc`)
        def sort
          @sort ||= if order_by_primary_key?
                      # Default order is by id DESC
                      :desc
                    else
                      # API defaults to DESC order if param `sort` not present
                      request_context.params[:sort]&.to_sym || :desc
                    end
        end

        # Do we only sort by primary key?
        def order_by_primary_key?
          keys.size == 1 && keys.first == primary_key
        end

        def primary_key
          relation.model.primary_key.to_sym
        end

        def sort_ascending?
          sort == :asc
        end

        # Build hash of request parameters for a given record (relevant to pagination)
        def params_for(record)
          return {} unless record

          keys.each_with_object({}) do |key, h|
            h["ks_prev_#{key}".to_sym] = record.attributes[key.to_s]
          end
        end

        private

        # All values present in request parameters that correspond to #keys.
        def values
          @values ||= keys.map do |key|
            request_context.params["ks_prev_#{key}".to_sym]
          end
        end

        # All keys relevant to pagination.
        # This always includes the primary key. Optionally, the `order_by` key is prepended.
        def keys
          @keys ||= [column_for_order_by(relation), primary_key].compact.uniq
        end
      end

      class KeysetPaginationStrategy
        attr_reader :request_context
        delegate :params, :header, :request, to: :request_context

        def initialize(request_context)
          @request_context = request_context
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def paginate(relation)
          pagination = KeysetPaginationInfo.new(relation, request_context)

          paged_relation = relation.limit(per_page)

          if conds = conditions(pagination)
            paged_relation = paged_relation.where(*conds)
          end

          # In all cases: sort by primary key (possibly in addition to another sort column)
          paged_relation = paged_relation.order(pagination.primary_key => pagination.sort)

          add_default_pagination_headers

          if last_record = paged_relation.last
            next_page_params = pagination.params_for(last_record)
            add_navigation_links(next_page_params)
          end

          paged_relation
        end
        # rubocop: enable CodeReuse/ActiveRecord

        private

        def conditions(pagination)
          fields = pagination.fields

          return nil if fields.empty?

          placeholder = fields.map { '?' }

          comp = if pagination.sort_ascending?
                   '>'
                 else
                   '<'
                 end

          [
            # Row value comparison:
            # (A, B) < (a, b) <=> (A < a) OR (A = a AND B < b)
            #     <=> A <= a AND ((A < a) OR (A = a AND B < b))
            "(#{fields.keys.join(',')}) #{comp} (#{placeholder.join(',')})",
            *fields.values
          ]
        end

        def per_page
          params[:per_page]
        end

        def add_default_pagination_headers
          header 'X-Per-Page',    per_page.to_s
        end

        def add_navigation_links(next_page_params)
          header 'X-Next-Page', page_href(next_page_params)
          header 'Link', link_for('next', next_page_params)
        end

        def page_href(next_page_params)
          request_url = request.url.split('?').first
          request_params = params.dup
          request_params[:per_page] = per_page

          request_params.merge!(next_page_params) if next_page_params

          "#{request_url}?#{request_params.to_query}"
        end

        def link_for(rel, next_page_params)
          %(<#{page_href(next_page_params)}>; rel="#{rel}")
        end
      end

      class DefaultPaginationStrategy
        attr_reader :request_context
        delegate :params, :header, :request, to: :request_context

        def initialize(request_context)
          @request_context = request_context
        end

        def paginate(relation)
          relation = add_default_order(relation)

          relation.page(params[:page]).per(params[:per_page]).tap do |data|
            add_pagination_headers(data)
          end
        end

        private

        # rubocop: disable CodeReuse/ActiveRecord
        def add_default_order(relation)
          if relation.is_a?(ActiveRecord::Relation) && relation.order_values.empty?
            relation = relation.order(:id)
          end

          relation
        end
        # rubocop: enable CodeReuse/ActiveRecord

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

        def data_without_counts?(paginated_data)
          paginated_data.is_a?(Kaminari::PaginatableWithoutCount)
        end
      end
    end
  end
end
