# frozen_string_literal: true

module UpdatedAtFilterable
  extend ActiveSupport::Concern

  included do
    scope :updated_before, ->(date) { where(scoped_table[:updated_at].lteq(date)) }
    scope :updated_after, ->(date) { where(scoped_table[:updated_at].gteq(date)) }

    def self.scoped_table
      arel_table.alias(table_name)
    end
  end
end
