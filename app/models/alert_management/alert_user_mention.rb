# frozen_string_literal: true

module AlertManagement
  class AlertUserMention < UserMention
    belongs_to :alert, class_name: '::AlertManagement::Alert',
      foreign_key: :alert_management_alert_id,
      inverse_of: :user_mentions

    belongs_to :note
  end
end
