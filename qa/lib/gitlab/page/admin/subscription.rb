# frozen_string_literal: true

module Gitlab
  module Page
    module Admin
      class Subscription < Chemlab::Page
        path '/admin/subscription'

        h2 :users_in_subscription
      end
    end
  end
end
