# frozen_string_literal: true

module Gitlab
  module Page
    module Admin
      class Dashboard < Chemlab::Page
        path '/admin'

        span :users_in_license
        span :billable_users
      end
    end
  end
end
