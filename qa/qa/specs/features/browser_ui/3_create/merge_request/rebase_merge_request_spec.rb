# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Merge request rebasing', product_group: :code_review do
      let(:merge_request) { Resource::MergeRequest.fabricate_via_api! }

      before do
        Flow::Login.sign_in
      end

      it 'user rebases source branch of merge request', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347735' do
        merge_request.project.visit!

        Page::Project::Menu.perform(&:go_to_merge_request_settings)
        Page::Project::Settings::MergeRequest.perform do |settings|
          settings.enable_ff_only
        end

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = merge_request.project
          commit.add_files([{ file_path: 'other.txt', content: 'New file added!' }])
        end

        merge_request.visit!

        Page::MergeRequest::Show.perform do |mr_page|
          expect(mr_page).to have_content('Merge blocked: the source branch must be rebased onto the target branch.', wait: 20)
          expect(mr_page).to be_fast_forward_not_possible
          expect(mr_page).not_to have_merge_button
          expect(merge_request.project.commits.size).to eq(2)

          mr_page.rebase!

          expect { mr_page.has_merge_button? }.to eventually_be_truthy.within(max_duration: 60, reload_page: mr_page)

          mr_page.merge!

          expect(merge_request.project.commits.size).to eq(3)
        end
      end
    end
  end
end
