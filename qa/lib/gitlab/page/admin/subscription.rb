# frozen_string_literal: true

module Gitlab
  module Page
    module Admin
      class Subscription < Chemlab::Page
        path '/admin/subscription'

        p :plan
        p :started
        p :name
        p :company
        p :email
        h2 :billable_users
        h2 :maximum_users
        h2 :users_in_subscription
        h2 :users_over_subscription
        table :subscription_history
      end
    end
  end
end
