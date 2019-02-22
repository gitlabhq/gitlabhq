# frozen_string_literal: true

module ClosedAtFilterable
  extend ActiveSupport::Concern

  included do
    scope :closed_before, ->(date) { where(scoped_table[:closed_at].lteq(date)) }
    scope :closed_after, ->(date) { where(scoped_table[:closed_at].gteq(date)) }

    def self.scoped_table
      arel_table.alias(table_name)
    end
  end
end
