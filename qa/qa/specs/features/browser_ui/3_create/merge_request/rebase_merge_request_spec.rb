# frozen_string_literal: true

module QA
  RSpec.describe 'Create', quarantine: { only: { subdomain: :staging }, issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/323990', type: :flaky } do
    describe 'Merge request rebasing' do
      it 'user rebases source branch of merge request', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1800' do
        Flow::Login.sign_in

        project = Resource::Project.fabricate_via_api! do |project|
          project.name = "only-fast-forward"
        end
        project.visit!

        Page::Project::Menu.perform(&:go_to_general_settings)
        Page::Project::Settings::Main.perform do |main|
          main.expand_merge_requests_settings do |settings|
            settings.enable_ff_only
          end
        end

        merge_request = Resource::MergeRequest.fabricate! do |merge_request|
          merge_request.project = project
          merge_request.title = 'Needs rebasing'
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.file_name = "other.txt"
          push.file_content = "New file added!"
          push.new_branch = false
        end

        merge_request.visit!

        Page::MergeRequest::Show.perform do |merge_request|
          expect(merge_request).to have_content('Needs rebasing')
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
