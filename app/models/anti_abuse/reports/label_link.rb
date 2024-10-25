# frozen_string_literal: true

module AntiAbuse
  module Reports
    class LabelLink < ApplicationRecord
      self.table_name = 'abuse_report_label_links'

      belongs_to :abuse_report, inverse_of: :label_links
      belongs_to :abuse_report_label, class_name: 'AntiAbuse::Reports::Label', inverse_of: :label_links

      validates :abuse_report, presence: true
      validates :abuse_report_label, presence: true, uniqueness: { scope: :abuse_report_id }
    end
  end
end
