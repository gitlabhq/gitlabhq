# frozen_string_literal: true

class AddSeatsInUseToGitlabSubscriptionHistory < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :gitlab_subscription_histories, :seats_in_use, :integer, null: true
  end
end
