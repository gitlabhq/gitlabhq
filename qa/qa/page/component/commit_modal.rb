# frozen_string_literal: true

module QA
  module Page
    module Component
      class CommitModal < Page::Base
        view 'app/assets/javascripts/projects/commit/components/form_modal.vue' do
          element 'submit-commit', required: true
        end
      end
    end
  end
end
