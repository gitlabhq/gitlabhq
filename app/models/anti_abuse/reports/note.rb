# frozen_string_literal: true

module AntiAbuse
  module Reports
    class Note < ApplicationRecord
      include Notes::ActiveRecord

      self.table_name = 'abuse_report_notes'
    end
  end
end
