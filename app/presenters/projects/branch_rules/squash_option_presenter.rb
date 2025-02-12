# frozen_string_literal: true

module Projects
  module BranchRules
    class SquashOptionPresenter < Gitlab::View::Presenter::Delegated
      presents ::Projects::BranchRules::SquashOption

      def help_text
        case squash_option
        when 'never'
          'Squashing is never performed and the checkbox is hidden.'
        when 'always'
          'Squashing is always performed. Checkbox is visible and selected, and users cannot change it.'
        when 'default_on'
          'Checkbox is visible and selected by default.'
        when 'default_off'
          'Checkbox is visible and unselected by default.'
        end
      end
    end
  end
end
