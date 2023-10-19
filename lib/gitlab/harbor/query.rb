# frozen_string_literal: true

module Gitlab
  module Harbor
    class Query
      include ActiveModel::Validations

      attr_reader :client, :repository_id, :artifact_id, :search, :limit, :sort, :page

      DEFAULT_LIMIT = 10
      SORT_REGEX = %r{\A(creation_time|update_time|name) (asc|desc)\z}

      validates :page, numericality: { greater_than: 0, integer: true }, allow_blank: true
      validates :limit, numericality: { greater_than: 0, less_than_or_equal_to: 25, integer: true }, allow_blank: true
      validates :repository_id, format: {
        with: /\A[a-zA-Z0-9\_\.\-$]+\z/,
        message: 'Id invalid'
      }, allow_blank: true
      validates :artifact_id, format: {
        with: /\A[a-zA-Z0-9\_\.\-$:]+\z/,
        message: 'Id invalid'
      }, allow_blank: true
      validates :sort, format: {
        with: SORT_REGEX,
        message: 'params invalid'
      }, allow_blank: true
      validates :search, format: {
        with: /\A(name=[a-zA-Z0-9\-:]+(?:,name=[a-zA-Z0-9\-:]+)*)\z/,
        message: 'params invalid'
      }, allow_blank: true

      def initialize(integration, params)
        @client = Client.new(integration)
        @repository_id = params[:repository_id]
        @artifact_id = params[:artifact_id]
        @search = params[:search]
        @limit = params[:limit]
        @sort = params[:sort]
        @page = params[:page]
        validate
      end

      def repositories
        result = @client.get_repositories(query_options)
        return [] if result[:total_count] == 0

        Kaminari.paginate_array(
          result[:body],
          limit: query_page_size,
          total_count: result[:total_count]
        )
      end

      def artifacts
        result = @client.get_artifacts(query_artifacts_options)
        return [] if result[:total_count] == 0

        Kaminari.paginate_array(
          result[:body],
          limit: query_page_size,
          total_count: result[:total_count]
        )
      end

      def tags
        result = @client.get_tags(query_tags_options)
        return [] if result[:total_count] == 0

        Kaminari.paginate_array(
          result[:body],
          limit: query_page_size,
          total_count: result[:total_count]
        )
      end

      private

      def query_artifacts_options
        options = query_options
        options[:repository_name] = repository_id
        options[:with_tag] = true

        options
      end

      def query_options
        options = {
          page: query_page,
          page_size: query_page_size
        }

        options[:q] = query_search if search.present?
        options[:sort] = query_sort if sort.present?

        options
      end

      def query_tags_options
        options = query_options
        options[:repository_name] = repository_id
        options[:artifact_name] = artifact_id

        options
      end

      def query_page
        page.presence || 1
      end

      def query_page_size
        (limit.presence || DEFAULT_LIMIT).to_i
      end

      def query_search
        search.gsub('=', '=~')
      end

      def query_sort
        match = sort.match(SORT_REGEX)
        order = (match[2] == 'asc' ? '' : '-')

        "#{order}#{match[1]}"
      end
    end
  end
end
