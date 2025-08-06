# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :code_review do
    describe 'Merge request batch suggestions' do
      let(:project) { create(:project, name: 'batch-suggestions-project') }
      let(:merge_request) do
        create(:merge_request,
          project: project,
          title: 'Needs some suggestions',
          description: '... so please add them.',
          file_content: File.read(
            Runtime::Path.fixture('metrics_dashboards', 'templating.yml')
          ))
      end

      let(:dev_user) { Runtime::User::Store.additional_test_user }

      before do
        project.add_member(dev_user)

        Flow::Login.sign_in(as: dev_user, skip_page_validation: true)

        merge_request.visit!

        Page::MergeRequest::Show.perform(&:click_diffs_tab)

        [4, 6, 10, 13].each do |line_number|
          Page::MergeRequest::Show.perform do |merge_request|
            merge_request.add_suggestion_to_diff("This is the suggestion for line number #{line_number}!", line_number)
          end
        end

        Flow::Login.sign_in

        merge_request.visit!
      end

      it 'applies multiple suggestions', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347682' do
        Page::MergeRequest::Show.perform do |merge_request|
          merge_request.click_diffs_tab
          4.times { merge_request.add_suggestion_to_batch }
          merge_request.apply_suggestion_with_message("Custom commit message")

          expect(merge_request).to have_suggestions_applied(4)
        end
      end
    end
  end
end
