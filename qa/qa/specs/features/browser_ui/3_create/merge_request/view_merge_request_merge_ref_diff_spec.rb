# frozen_string_literal: true

module QA
  RSpec.describe 'Create', :requires_admin, quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/261793', type: :investigating } do
    describe 'View merge request merge-ref diff' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'merge-ref-diff'
        end
      end

      let(:merge_request) do
        Resource::MergeRequest.fabricate_via_api! do |merge_request|
          merge_request.project = project
          merge_request.title = 'This is a merge request'
          merge_request.description = '... for viewing merge-ref and merge-base diffs'
          merge_request.file_content = 'This exists on the source branch only'
        end
      end

      let(:new_file_name) { "added_file-#{SecureRandom.hex(8)}.txt" }

      context 'when the feature flag default_merge_ref_for_diffs is enabled' do
        before do
          Runtime::Feature.enable('default_merge_ref_for_diffs', project: project)

          commit_to_branch(merge_request.target_branch, new_file_name)
          commit_to_branch(merge_request.source_branch, new_file_name)

          Flow::Login.sign_in

          merge_request.visit!
        end

        it 'views the merge-ref diff by default' do
          Page::MergeRequest::Show.perform do |mr_page|
            mr_page.click_diffs_tab
            mr_page.click_target_version_dropdown

            expect(mr_page.version_dropdown_content).to include('master (HEAD)')
            expect(mr_page.version_dropdown_content).not_to include('master (base)')
            expect(mr_page).to have_file(merge_request.file_name)
            expect(mr_page).not_to have_file(new_file_name)
          end
        end
      end

      context 'when the feature flag default_merge_ref_for_diffs is disabled' do
        before do
          Runtime::Feature.disable('default_merge_ref_for_diffs', project: project)

          commit_to_branch(merge_request.target_branch, new_file_name)
          commit_to_branch(merge_request.source_branch, new_file_name)

          Flow::Login.sign_in

          merge_request.visit!
        end

        it 'views the merge-base diff by default' do
          Page::MergeRequest::Show.perform do |mr_page|
            mr_page.click_diffs_tab
            mr_page.click_target_version_dropdown

            expect(mr_page.version_dropdown_content).to include('master (HEAD)')
            expect(mr_page.version_dropdown_content).to include('master (base)')
            expect(mr_page).to have_file(merge_request.file_name)
            expect(mr_page).to have_file(new_file_name)
          end
        end
      end

      def commit_to_branch(branch, file)
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = merge_request.project
          commit.branch = branch
          commit.commit_message = "Add new file on #{branch}"
          commit.add_files(
            [
                {
                    file_path: file,
                    content: "This exists on source and target branches"
                }
            ]
          )
        end
      end
    end
  end
end
