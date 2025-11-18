# frozen_string_literal: true

module QA
  RSpec.describe 'Create', feature_category: :code_review_workflow do
    describe 'Merge request dashboard' do
      it 'renders merge requests', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/578323' do
        Flow::Login.sign_in

        Resource::MergeRequest.fabricate! do |merge_request|
          merge_request.title = "Dashboard merge request"
        end

        Page::Main::Menu.perform(&:go_to_merge_request_dashboard)

        Page::Dashboard::MergeRequests.perform do |merge_requests|
          expect(merge_requests).to have_element('data-testid': 'merge-request-dashboard-list')
          expect(merge_requests).to have_content("Dashboard merge request")
        end
      end
    end
  end
end
