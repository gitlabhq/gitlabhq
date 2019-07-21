# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'issue suggestions' do
      let(:issue_title) { 'Issue Lists are awesome' }

      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        project = Resource::Project.fabricate_via_api! do |resource|
          resource.name = 'project-for-issue-suggestions'
          resource.description = 'project for issue suggestions'
        end

        Resource::Issue.fabricate_via_api! do |issue|
          issue.title = issue_title
          issue.project = project
        end

        project.visit!
      end

      it 'user sees issue suggestions when creating a new issue' do
        Page::Project::Show.perform(&:go_to_new_issue)
        Page::Project::Issue::New.perform do |new|
          new.add_title("issue")
          expect(new).to have_content(issue_title)

          new.add_title("Issue Board")
          expect(new).not_to have_content(issue_title)
        end
      end
    end
  end
end
