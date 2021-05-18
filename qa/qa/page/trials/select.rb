# frozen_string_literal: true

module QA
  module Page
    module Trials
      class Select < Chemlab::Page
        path '/-/trials/select'

        # TODO: Supplant with data-qa-selectors
        select :subscription_for, id: 'namespace_id'
        text_field :new_group_name, id: 'new_group_name'
        button :start_your_free_trial, value: 'Start your free trial'
        radio :trial_company, id: 'trial_entity_company'
        radio :trial_individual, id: 'trial_entity_individual'
      end
    end
  end
end
