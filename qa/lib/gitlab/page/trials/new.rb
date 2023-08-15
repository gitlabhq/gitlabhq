# frozen_string_literal: true

module Gitlab
  module Page
    module Trials
      class New < Chemlab::Page
        path '/-/trials/new'

        text_field :first_name
        text_field :last_name
        text_field :company_name
        select :company_size
        text_field :phone_number
        select :country
        select :state
        button :continue
      end
    end
  end
end
