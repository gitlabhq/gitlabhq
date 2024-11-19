# frozen_string_literal: true

module AntiAbuse
  module Reports
    class Label < ApplicationRecord
      include BaseLabel

      self.table_name = 'abuse_report_labels'

      has_many :label_links, foreign_key: :abuse_report_label_id, inverse_of: :abuse_report_label,
        class_name: 'AntiAbuse::Reports::LabelLink'
      has_many :abuse_reports, through: :label_links

      validates :title, uniqueness: true
      validates :description, length: { maximum: 500 }
    end
  end
end
