# frozen_string_literal: true

module Gitlab
  module Page
    module Admin
      class Dashboard < Chemlab::Page
        path '/admin'

        h2 :users_in_license
        h2 :billable_users
        h3 :number_of_users
      end
    end
  end
end
