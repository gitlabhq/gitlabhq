# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'issue suggestions' do
      let(:issue_title) { 'Issue Lists are awesome' }

      it 'user sees issue suggestions when creating a new issue' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        project = Resource::Project.fabricate_via_api! do |resource|
          resource.name = 'project-for-issue-suggestions'
          resource.description = 'project for issue suggestions'
        end

        Resource::Issue.fabricate_via_browser_ui! do |issue|
          issue.title = issue_title
          issue.project = project
        end

        project.visit!

        Page::Project::Show.perform(&:go_to_new_issue)
        Page::Project::Issue::New.perform do |new_issue_page|
          new_issue_page.add_title("issue")
          expect(new_issue_page).to have_content(issue_title)

          new_issue_page.add_title("Issue Board")
          expect(new_issue_page).not_to have_content(issue_title)
        end
      end
    end
  end
end
