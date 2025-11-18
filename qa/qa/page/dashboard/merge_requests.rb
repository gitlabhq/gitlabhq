# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      class MergeRequests < Page::Base
        view 'app/assets/javascripts/merge_request_dashboard/components/app.vue' do
          element 'merge-request-dashboard-list', required: true
        end
      end
    end
  end
end
