# frozen_string_literal: true

class IncreaseSelfHostedAttachmentSizeLimit < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    change_column_default :application_settings, :max_attachment_size, from: 10, to: 100
  end

  def down
    change_column_default :application_settings, :max_attachment_size, from: 100, to: 10
  end
end
