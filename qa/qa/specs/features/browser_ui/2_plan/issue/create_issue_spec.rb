# frozen_string_literal: true

module QA
  context 'Plan', :smoke do
    describe 'Issue creation' do
      let(:issue_title) { 'issue title' }

      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
      end

      it 'user creates an issue' do
        Resource::Issue.fabricate_via_browser_ui! do |issue|
          issue.title = issue_title
        end

        Page::Project::Menu.perform(&:click_issues)

        expect(page).to have_content(issue_title)
      end

      context 'when using attachments in comments', :object_storage do
        let(:file_to_attach) do
          File.absolute_path(File.join('spec', 'fixtures', 'banana_sample.gif'))
        end

        before do
          issue = Resource::Issue.fabricate_via_api! do |issue|
            issue.title = issue_title
          end

          issue.visit!
        end

        it 'user comments on an issue with an attachment' do
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
    end
  end
end
