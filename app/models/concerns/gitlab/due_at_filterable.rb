# frozen_string_literal: true

module Gitlab
  module DueAtFilterable
    extend ActiveSupport::Concern

    included do
      scope :due_before, ->(date) { where(scoped_table[:due_date].lteq(date)) }
      scope :due_after, ->(date) { where(scoped_table[:due_date].gteq(date)) }

      def self.scoped_table
        arel_table.alias(table_name)
      end
    end
  end
end
