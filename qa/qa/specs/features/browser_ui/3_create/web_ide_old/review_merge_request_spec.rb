# frozen_string_literal: true

# TODO: remove this test when coverage is replaced or deemed irrelevant
module QA
  RSpec.describe 'Create', :skip_live_env, product_group: :ide do
    before do
      skip("Skipped but kept as reference. https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115741#note_1330720944")
    end

    describe 'Review a merge request in Web IDE' do
      let(:new_file) { 'awesome_new_file.txt' }
      let(:original_text) { 'Text' }
      let(:review_text) { 'Reviewed ' }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'review-merge-request-spec-project'
          project.initialize_with_readme = true
        end
      end

      let(:merge_request) do
        Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.file_name = new_file
          mr.file_content = original_text
          mr.project = project
        end
      end

      before do
        Flow::Login.sign_in
        merge_request.visit!
      end

      it 'opens and edits a merge request in Web IDE', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347786' do
        Page::MergeRequest::Show.perform do |show|
          show.click_open_in_web_ide
        end

        Page::Project::WebIDE::Edit.perform do |ide|
          ide.wait_until_ide_loads
          ide.has_file?(new_file)
          ide.add_to_modified_content(review_text)
          ide.commit_changes
        end

        merge_request.visit!

        Page::MergeRequest::Show.perform do |show|
          show.click_diffs_tab
          expect(show).to have_content(review_text)
        end
      end
    end
  end
end
