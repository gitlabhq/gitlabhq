# frozen_string_literal: true

module SavedReplyConcern
  extend ActiveSupport::Concern

  included do
    validates namespace_foreign_key, :name, :content, presence: true
    validates :content, length: { maximum: 10000 }
    validates :name,
      length: { maximum: 255 },
      uniqueness: { scope: [namespace_foreign_key] }

    scope :order_by_name, -> { order(arel_table[:name].lower.asc) }

    def self.find_saved_reply(**args)
      find_by(args)
    end
  end
end
