# frozen_string_literal: true

module Gitlab
  module Zentao
    class Query
      STATUSES = %w[all opened closed].freeze
      ISSUES_DEFAULT_LIMIT = 20
      ISSUES_MAX_LIMIT = 50

      def initialize(integration, params)
        @client = Client.new(integration)
        @params = params
      end

      def issues
        issues_response = client.fetch_issues(query_options)
        return [] if issues_response.blank?

        Kaminari.paginate_array(
          issues_response['issues'],
          limit: issues_response['limit'],
          total_count: issues_response['total']
        )
      end

      def issue
        issue_response = client.fetch_issue(params[:id])
        issue_response['issue']
      end

      private

      attr_reader :client, :params

      def query_options
        {
          order: query_order,
          status: query_status,
          labels: query_labels,
          page: query_page,
          limit: query_limit,
          search: query_search
        }
      end

      def query_page
        params[:page].presence || 1
      end

      def query_limit
        limit = params[:limit].presence || ISSUES_DEFAULT_LIMIT
        [limit.to_i, ISSUES_MAX_LIMIT].min
      end

      def query_search
        params[:search] || ''
      end

      def query_order
        key, order = params['sort'].to_s.split('_', 2)
        zentao_key = (key == 'created' ? 'openedDate' : 'lastEditedDate')
        zentao_order = (order == 'asc' ? 'asc' : 'desc')

        "#{zentao_key}_#{zentao_order}"
      end

      def query_status
        return params[:state] if params[:state].present? && params[:state].in?(STATUSES)

        'opened'
      end

      def query_labels
        (params[:labels].presence || []).join(',')
      end
    end
  end
end
