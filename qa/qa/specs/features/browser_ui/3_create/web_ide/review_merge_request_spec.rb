# frozen_string_literal: true

module QA
  context 'Create', quarantine: { type: :new } do
    describe 'Review a merge request in Web IDE' do
      let(:new_file) { 'awesome_new_file.txt' }
      let(:review_text) { 'Reviewed ' }

      let(:merge_request) do
        Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.file_name = new_file
          mr.file_content = 'Text'
        end
      end

      before do
        Flow::Login.sign_in

        merge_request.visit!
      end

      it 'opens and edits a merge request in Web IDE' do
        Page::MergeRequest::Show.perform do |show|
          show.click_open_in_web_ide
        end

        Page::Project::WebIDE::Edit.perform do |ide|
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
