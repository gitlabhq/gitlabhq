# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :smoke, :health_check, product_group: :project_management do
    describe 'Issue creation' do
      let(:project) do
        Resource::Project.fabricate_via_api_unless_fips! do |project|
          project.name = "project-create-issue-#{SecureRandom.hex(8)}"
          project.personal_namespace = Runtime::User.username
          project.description = nil
        end
      end

      let(:closed_issue) do
        Resource::Issue.fabricate_via_api_unless_fips! { |issue| issue.project = project }
      end

      before do
        Flow::Login.sign_in
      end

      it(
        'creates an issue',
        :mobile,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347989'
      ) do
        issue = Resource::Issue.fabricate_via_browser_ui! { |issue| issue.project = project }

        Page::Project::Menu.perform(&:go_to_issues)

        Page::Project::Issue::Index.perform do |index|
          expect(index).to have_issue(issue)
        end
      end

      it(
        'closes an issue',
        :mobile,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347967'
      ) do
        closed_issue.visit!

        Page::Project::Issue::Show.perform do |issue_page|
          issue_page.click_close_issue_button

          expect(issue_page).to have_reopen_issue_button
        end

        Page::Project::Menu.perform(&:go_to_issues)

        Page::Project::Issue::Index.perform do |index|
          expect(index).not_to have_issue(closed_issue)

          index.click_closed_issues_tab

          expect(index).to have_issue(closed_issue)
        end
      end

      context 'when using attachments in comments', :object_storage do
        let(:png_file_name) { 'testfile.png' }
        let(:file_to_attach) { Runtime::Path.fixture('designs', png_file_name) }

        before do
          Resource::Issue.fabricate_via_api_unless_fips! { |issue| issue.project = project }.visit!
        end

        it(
          'comments on an issue with an attachment',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347946'
        ) do
          Page::Project::Issue::Show.perform do |show|
            show.comment('See attached image for scale', attachment: file_to_attach)

            expect(show.noteable_note_item.find("img[src$='#{png_file_name}']")).to be_visible
          end
        end
      end
    end
  end
end
