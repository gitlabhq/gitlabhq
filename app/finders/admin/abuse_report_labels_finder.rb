# frozen_string_literal: true

module Admin
  class AbuseReportLabelsFinder
    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
    end

    def execute
      return AntiAbuse::Reports::Label.none unless current_user&.can_admin_all_resources?

      items = AntiAbuse::Reports::Label.all
      items = by_search(items)

      items.order(title: :asc) # rubocop: disable CodeReuse/ActiveRecord
    end

    private

    attr_reader :current_user, :params

    def by_search(labels)
      return labels unless search_term

      labels.search(search_term)
    end

    def search_term
      params[:search_term]
    end
  end
end
