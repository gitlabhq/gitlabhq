# frozen_string_literal: true

module Users
  class SavedReply < ApplicationRecord
    self.table_name = 'saved_replies'

    belongs_to :user

    validates :user_id, :name, :content, presence: true
    validates :name,
      length: { maximum: 255 },
      uniqueness: { scope: [:user_id] }
    validates :content, length: { maximum: 10000 }

    def self.find_saved_reply(user_id:, id:)
      ::Users::SavedReply.find_by(user_id: user_id, id: id)
    end
  end
end
