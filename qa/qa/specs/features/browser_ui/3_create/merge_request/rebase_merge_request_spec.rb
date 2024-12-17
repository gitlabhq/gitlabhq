# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Merge request rebasing', product_group: :code_review do
      let(:merge_request) { create(:merge_request) }

      before do
        Flow::Login.sign_in
      end

      it 'user rebases source branch of merge request', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347735' do
        merge_request.project.visit!

        Page::Project::Menu.perform(&:go_to_merge_request_settings)
        Page::Project::Settings::MergeRequest.perform do |settings|
          settings.enable_ff_only
        end

        create(:commit, project: merge_request.project, actions: [
          { action: 'create', file_path: 'other.txt', content: 'New file added!' }
        ])

        merge_request.visit!
        Page::MergeRequest::Show.perform do |mr_page|
          expect(mr_page).to have_content('Merge blocked: 1 check failed', wait: 20)
          mr_page.expand_merge_checks
          expect(mr_page).to have_content('Merge request must be rebased, because a fast-forward merge is not possible.')

          expect(mr_page).not_to have_merge_button
          expect(merge_request.project.commits.size).to eq(2), "Expected 2 commits, got: #{merge_request.project.commits.size}"

          mr_page.rebase!

          expect { mr_page.has_merge_button? }.to eventually_be_truthy.within(max_duration: 60, reload_page: mr_page)

          mr_page.merge!

          expect(merge_request.project.commits.size).to eq(3), "Expected 3 commits, got: #{merge_request.project.commits.size}"
        end
      end
    end
  end
end
