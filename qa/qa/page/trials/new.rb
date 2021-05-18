# frozen_string_literal: true

module QA
  module Page
    module Trials
      class New < Chemlab::Page
        path '/-/trials/new'

        # TODO: Supplant with data-qa-selectors
        text_field :first_name, id: 'first_name'
        text_field :last_name, id: 'last_name'
        text_field :company_name, id: 'company_name'
        select :number_of_employees, id: 'company_size'
        text_field :telephone_number, id: 'phone_number'
        text_field :number_of_users, id: 'number_of_users'

        select :country, id: 'country_select'

        button :continue, value: 'Continue'
      end
    end
  end
end
