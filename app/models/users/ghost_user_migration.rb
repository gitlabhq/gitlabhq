# frozen_string_literal: true

module Users
  class GhostUserMigration < ApplicationRecord
    self.table_name = 'ghost_user_migrations'

    enum :user_type, HasUserType::USER_TYPES

    belongs_to :user
    belongs_to :initiator_user, class_name: 'User'

    validates :user_id, presence: true

    before_create :set_user_type

    scope :consume_order, -> { order(:consume_after, :id) }
    scope :for_humans, -> { where(user_type: :human) }
    scope :for_non_humans, -> { where.not(user_type: :human) }

    private

    def set_user_type
      self.user_type = user.user_type
    end
  end
end
