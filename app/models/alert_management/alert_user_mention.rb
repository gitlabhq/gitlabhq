# frozen_string_literal: true

module AlertManagement
  class AlertUserMention < UserMention
    belongs_to :alert_management_alert, class_name: '::AlertManagement::Alert'
    belongs_to :note
  end
end
