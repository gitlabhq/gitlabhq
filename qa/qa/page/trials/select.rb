# frozen_string_literal: true

module QA
  module Page
    module Trials
      class Select < Chemlab::Page
        path '/-/trials/select'

        select :subscription_for
        text_field :new_group_name
        button :start_your_free_trial
        radio :trial_company
        radio :trial_individual
      end
    end
  end
end
