# frozen_string_literal: true

module SavedReplyConcern
  extend ActiveSupport::Concern

  included do
    validates namespace_foreign_key, :name, :content, presence: true
    validates :content, length: { maximum: 10000 }
    validates :name,
      length: { maximum: 255 },
      uniqueness: { scope: [namespace_foreign_key] }

    def self.find_saved_reply(**args)
      find_by(args)
    end
  end
end
