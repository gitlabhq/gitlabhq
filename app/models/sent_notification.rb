# frozen_string_literal: true

class SentNotification < ApplicationRecord
  # Add every change in SentNotificationsShared as two models should currently share the same logic
  # while we partition the table.
  include SentNotificationsShared

  def partitioned_reply_key
    reply_key
  end
end
