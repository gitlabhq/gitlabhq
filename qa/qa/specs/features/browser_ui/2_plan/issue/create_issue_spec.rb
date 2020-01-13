# frozen_string_literal: true

module QA
  context 'Plan', :smoke do
    describe 'Issue creation' do
      let(:issue_title) { 'issue title' }

      before do
        Flow::Login.sign_in
      end

      it 'user creates an issue' do
        issue = Resource::Issue.fabricate_via_browser_ui! do |issue|
          issue.title = issue_title
        end

        Page::Project::Menu.perform(&:click_issues)

        Page::Project::Issue::Index.perform do |index|
          expect(index).to have_issue(issue)
        end
      end

      context 'when using attachments in comments', :object_storage do
        let(:gif_file_name) { 'banana_sample.gif' }
        let(:file_to_attach) do
          File.absolute_path(File.join('spec', 'fixtures', gif_file_name))
        end

        before do
          Resource::Issue.fabricate_via_api! do |issue|
            issue.title = issue_title
          end.visit!
        end

        it 'user comments on an issue with an attachment' do
          Page::Project::Issue::Show.perform do |show|
            show.comment('See attached banana for scale', attachment: file_to_attach)

            expect(show.noteable_note_item.find("img[src$='#{gif_file_name}']")).to be_visible
          end
        end
      end
    end
  end
end
