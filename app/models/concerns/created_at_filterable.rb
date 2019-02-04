# frozen_string_literal: true

module CreatedAtFilterable
  extend ActiveSupport::Concern

  included do
    scope :created_before, ->(date) { where(scoped_table[:created_at].lteq(date)) }
    scope :created_after, ->(date) { where(scoped_table[:created_at].gteq(date)) }

    def self.scoped_table
      arel_table.alias(table_name)
    end
  end
end
