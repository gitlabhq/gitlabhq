# frozen_string_literal: true

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

      class Base
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

      class KeysetPaginationStrategy < Base
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

          return if fields.empty?

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

        def add_default_pagination_headers
          header 'X-Per-Page', per_page.to_s
        end

        def add_navigation_links(next_page_params)
          header 'X-Next-Page', page_href(next_page_params)
          header 'Link', link_for('next', next_page_params)
        end

        def link_for(rel, next_page_params)
          %(<#{page_href(next_page_params)}>; rel="#{rel}")
        end
      end

      class DefaultPaginationStrategy < Base
        attr_reader :request_context
        delegate :params, :header, :request, to: :request_context

        def initialize(request_context)
          @request_context = request_context
        end

        def paginate(relation)
          paginate_with_limit_optimization(add_default_order(relation)).tap do |data|
            add_pagination_headers(data)
          end
        end

        private

        def paginate_with_limit_optimization(relation)
          pagination_data = relation.page(params[:page]).per(params[:per_page])
          return pagination_data unless pagination_data.is_a?(ActiveRecord::Relation)
          return pagination_data unless Feature.enabled?(:api_kaminari_count_with_limit)

          limited_total_count = pagination_data.total_count_with_limit
          if limited_total_count > Kaminari::ActiveRecordRelationMethods::MAX_COUNT_LIMIT
            # The call to `total_count_with_limit` memoizes `@arel` because of a call to `references_eager_loaded_tables?`
            # We need to call `reset` because `without_count` relies on `@arel` being unmemoized
            pagination_data.reset.without_count
          else
            pagination_data
          end
        end

        def add_default_order(relation)
          if relation.is_a?(ActiveRecord::Relation) && relation.order_values.empty?
            relation = relation.order(:id) # rubocop: disable CodeReuse/ActiveRecord
          end

          relation
        end

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
          [].tap do |links|
            links << %(<#{page_href(page: paginated_data.prev_page)}>; rel="prev") if paginated_data.prev_page
            links << %(<#{page_href(page: paginated_data.next_page)}>; rel="next") if paginated_data.next_page
            links << %(<#{page_href(page: 1)}>; rel="first")

            links << %(<#{page_href(page: total_pages(paginated_data))}>; rel="last") unless data_without_counts?(paginated_data)
          end.join(', ')
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
