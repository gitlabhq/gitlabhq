# frozen_string_literal: true

module Users
  class SavedReply < ApplicationRecord
    def self.namespace_foreign_key
      :user_id
    end
    self.table_name = 'saved_replies'

    include SavedReplyConcern

    belongs_to :user
  end
end
