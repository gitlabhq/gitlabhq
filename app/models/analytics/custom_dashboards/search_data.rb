# frozen_string_literal: true

module Analytics
  module CustomDashboards
    class SearchData < ApplicationRecord # rubocop: disable Search/NamespacedClass -- Not related to Elastic or Zoekt search domain
      self.table_name = 'custom_dashboard_search_data'

      belongs_to :dashboard,
        class_name: 'Analytics::CustomDashboards::Dashboard',
        foreign_key: :custom_dashboard_id,
        inverse_of: :search_data,
        optional: false

      validates :name, presence: true, length: { maximum: 255 }
      validates :description, length: { maximum: 2048 }
    end # rubocop: enable Search/NamespacedClass
  end
end
