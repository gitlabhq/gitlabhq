module QA
  context 'Plan' do
    describe 'Editing scoped labels on issues' do
      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        @initial_label = 'animal::fox'
        @new_label_same_scope = 'animal::dolphin'
        @new_label_different_scope = 'plant::orchid'

        issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.title = 'Issue to test the scoped labels'
          issue.labels = @initial_label
        end

        [@new_label_same_scope, @new_label_different_scope].each do |label|
          Resource::Label.fabricate_via_api! do |l|
            l.project = issue.project.id
            l.title = label
          end
        end

        issue.visit!
      end

      it 'correctly applies scoped labels depending on if they are from the same or a different scope' do
        Page::Project::Issue::Show.perform do |issue_page|
          issue_page.select_labels_and_refresh [@new_label_same_scope, @new_label_different_scope]

          expect(page).to have_content("added #{@initial_label}")
          expect(page).to have_content("added #{@new_label_same_scope} #{@new_label_different_scope} labels and removed #{@initial_label}")
          expect(issue_page.text_of_labels_block).to have_content(@new_label_same_scope)
          expect(issue_page.text_of_labels_block).to have_content(@new_label_different_scope)
          expect(issue_page.text_of_labels_block).not_to have_content(@initial_label)
        end
      end
    end
  end
end
