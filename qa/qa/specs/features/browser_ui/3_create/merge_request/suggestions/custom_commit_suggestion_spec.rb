# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Merge request suggestions', product_group: :code_review do
      let(:commit_message) { 'Applying suggested change for testing purposes.' }
      let(:project) { create(:project, name: 'mr-suggestions-project') }
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

        Page::MergeRequest::Show.perform do |merge_request|
          merge_request.click_diffs_tab
          merge_request.add_suggestion_to_diff('This is the suggestion for line number 4!', 4)
        end

        Flow::Login.sign_in
        merge_request.visit!
      end

      it 'applies a single suggestion with a custom message',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347711' do
        Page::MergeRequest::Show.perform do |merge_request|
          merge_request.click_diffs_tab
          merge_request.apply_suggestion_with_message(commit_message)

          expect(merge_request).to have_suggestions_applied

          merge_request.click_commits_tab

          # Commit does not always display immediately and may require a page refresh
          # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/368735
          # TODO: Remove page refresh logic once issue is resolved.
          Support::Retrier.retry_on_exception(max_attempts: 2, reload_page: merge_request) do
            expect(merge_request).to have_content(commit_message)
          end
        end
      end
    end
  end
end
