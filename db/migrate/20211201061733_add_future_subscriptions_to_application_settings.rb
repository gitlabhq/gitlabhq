# frozen_string_literal: true

class AddFutureSubscriptionsToApplicationSettings < Gitlab::Database::Migration[1.0]
  def change
    add_column :application_settings, :future_subscriptions, :jsonb, null: false, default: []
  end
end
