# frozen_string_literal: true

module Users
  class BroadcastMessageDismissal < ApplicationRecord
    belongs_to :user
    belongs_to :broadcast_message, class_name: 'System::BroadcastMessage'

    validates :user, presence: true, uniqueness: { scope: :broadcast_message_id }
    validates :broadcast_message, presence: true

    self.table_name = 'user_broadcast_message_dismissals'

    scope :valid_dismissals, -> { where('expires_at > :now', now: Time.current) }
    scope :for_user, ->(user) do
      where(user: user)
    end

    BROADCAST_MESSAGE_DISMISSAL_COOKIE_KEY = 'hide_broadcast_message_'

    def cookie_key
      self.class.get_cookie_key(broadcast_message.id)
    end

    class << self
      def find_or_initialize_dismissal(user, broadcast_message_id)
        find_or_initialize_by(user: user, broadcast_message_id: broadcast_message_id)
      end

      def get_cookie_key(broadcast_message_id)
        "#{BROADCAST_MESSAGE_DISMISSAL_COOKIE_KEY}#{broadcast_message_id}"
      end
    end
  end
end
