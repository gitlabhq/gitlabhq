# frozen_string_literal: true

module QA
  context 'Plan', :smoke do
    describe 'Issue creation' do
      let(:issue_title) { 'issue title' }

      it 'user creates an issue' do
        create_issue

        Page::Project::Menu.perform(&:click_issues)

        expect(page).to have_content(issue_title)
      end

      context 'when using attachments in comments', :object_storage do
        let(:file_to_attach) do
          File.absolute_path(File.join('spec', 'fixtures', 'banana_sample.gif'))
        end

        it 'user comments on an issue with an attachment' do
          create_issue

          Page::Project::Issue::Show.perform do |show|
            show.comment('See attached banana for scale', attachment: file_to_attach)

            show.refresh

            image_url = find('a[href$="banana_sample.gif"]')[:href]

            found = show.wait(reload: false) do
              show.asset_exists?(image_url)
            end

            expect(found).to be_truthy
          end
        end
      end

      def create_issue
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        Resource::Issue.fabricate_via_browser_ui! do |issue|
          issue.title = issue_title
        end
      end
    end
  end
end
