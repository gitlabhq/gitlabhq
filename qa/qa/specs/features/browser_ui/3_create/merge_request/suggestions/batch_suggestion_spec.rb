# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    context 'Add batch suggestions to a Merge Request', :transient do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'suggestions_project'
        end
      end

      let(:merge_request) do
        Resource::MergeRequest.fabricate_via_api! do |merge_request|
          merge_request.project = project
          merge_request.title = 'Needs some suggestions'
          merge_request.description = '... so please add them.'
          merge_request.file_content = File.read(
            Pathname
              .new(__dir__)
              .join('../../../../../../fixtures/metrics_dashboards/templating.yml')
          )
        end
      end

      let(:dev_user) do
        Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
      end

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

      it 'applies multiple suggestions', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1177' do
        Page::MergeRequest::Show.perform do |merge_request|
          merge_request.click_diffs_tab
          4.times { merge_request.add_suggestion_to_batch }
          merge_request.apply_suggestions_batch

          expect(merge_request).to have_css('.badge-success', text: "Applied", count: 4)
        end
      end
    end
  end
end
