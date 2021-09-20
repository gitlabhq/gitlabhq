# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Merge request rebasing' do
      let(:merge_request) { Resource::MergeRequest.fabricate_via_api! }

      before do
        Flow::Login.sign_in
      end

      it 'user rebases source branch of merge request', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1596' do
        merge_request.project.visit!

        Page::Project::Menu.perform(&:go_to_general_settings)
        Page::Project::Settings::Main.perform do |main|
          main.expand_merge_requests_settings do |settings|
            settings.enable_ff_only
          end
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = merge_request.project
          push.file_name = "other.txt"
          push.file_content = "New file added!"
          push.new_branch = false
        end

        merge_request.visit!

        Page::MergeRequest::Show.perform do |merge_request|
          expect(merge_request).to have_content('Merge blocked: the source branch must be rebased onto the target branch.')
          expect(merge_request).to be_fast_forward_not_possible
          expect(merge_request).not_to have_merge_button

          merge_request.rebase!

          expect(merge_request).to have_merge_button
          expect(merge_request).to be_fast_forward_possible
        end
      end
    end
  end
end
