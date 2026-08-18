# frozen_string_literal: true

class AddDuoPrivacyNoticeAcknowledgedAtToChatNames < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    add_column :chat_names, :duo_privacy_notice_acknowledged_at, :datetime_with_timezone
  end
end
