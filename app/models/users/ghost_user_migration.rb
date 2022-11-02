# frozen_string_literal: true

module Users
  class GhostUserMigration < ApplicationRecord
    self.table_name = 'ghost_user_migrations'

    belongs_to :user
    belongs_to :initiator_user, class_name: 'User'

    validates :user_id, presence: true

    scope :consume_order, -> { order(:consume_after, :id) }
  end
end
