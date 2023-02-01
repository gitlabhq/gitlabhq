# frozen_string_literal: true

module Gitlab
  module Page
    module Trials
      class Select < Chemlab::Page
        path '/-/trials/select'

        button :select_group, 'data-testid': 'base-dropdown-toggle'
        div :group_dropdown, 'data-testid': 'base-dropdown-menu'
        text_field :new_group_name
        button :start_your_free_trial
        radio :trial_company
        radio :trial_individual

        def subscription_for=(group_name)
          select_group

          group_dropdown_element.span(text: /#{group_name}/).click
        end
      end
    end
  end
end
