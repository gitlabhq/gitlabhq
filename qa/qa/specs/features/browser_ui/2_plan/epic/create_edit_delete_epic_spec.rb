# frozen_string_literal: true

module QA
  context :plan do
    describe 'Epics Creation' do
      let!(:issue) do
        Factory::Resource::Issue.fabricate! do |issue|
          issue.title = 'Issue for epics tests'
        end
      end

      before(:all) do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }
      end

      it 'user creates, edits, deletes epic' do
        epic = EE::Factory::Resource::Epic.fabricate! do |epic|
          epic.title = "My First Epic"
        end

        expect(page).to have_content(/My First Epic/)

        # Edit Epics
        EE::Page::Group::Epic::Show.act { go_to_edit_page }

        EE::Page::Group::Epic::Edit.perform do |edit_page|
          edit_page.set_description("My Edited Epic Description")
          edit_page.set_title("My Edited Epic")
          edit_page.save_changes
          expect(edit_page).to have_content(/My Edited Epic/)
        end

        # Add/Remove Issues to/from Epics
        EE::Page::Group::Epic::Show.perform do |show_page|
          show_page.add_issue_to_epic(issue.location)
          show_page.remove_issue_from_epic
          expect(show_page).to have_content(/removed issue/)
        end

        # Comment on Epics
        EE::Page::Group::Epic::Show.act { add_comment_to_epic("My Epic Comments") }

        expect(page).to have_content(/My Epic Comments/)

        # Add Issue to Epic using quick actions
        issue.visit!

        Page::Project::Issue::Show.perform do |show_page|
          show_page.comment("/epic #{epic.location}")
          show_page.comment("/remove_epic")
          expect(show_page).to have_content(/removed from epic/)
        end

        epic.visit!

        expect(page).to have_content("added issue", count: 2)
        expect(page).to have_content("removed issue", count: 2)

        # Close Epic
        EE::Page::Group::Epic::Show.act { close_reopen_epic }

        expect(page).to have_content(/Closed/)

        # Reopen Epic
        EE::Page::Group::Epic::Show.act { close_reopen_epic }

        expect(page).to have_content(/Open/)

        # Delete Epics
        EE::Page::Group::Epic::Show.act { go_to_edit_page }

        EE::Page::Group::Epic::Edit.perform do |edit_page|
          edit_page.delete_epic
          expect(edit_page).to have_content(/The epic was successfully deleted/)
        end
      end
    end
  end
end
