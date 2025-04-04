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

      before do
        Flow::Login.sign_in
      end

      it(
        'creates an issue',
        :mobile,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347989'
      ) do
        resource, index_page_type = create_new_issue

        Page::Project::Menu.perform(&:go_to_work_items)

        index_page_type.perform do |index|
          expect(index).to have_issue(resource)
        end
      end

      it(
        'closes an issue',
        :mobile,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347967'
      ) do
        resource, index_page_type, show_page_type = create_new_issue
        resource.visit!

        show_page_type.perform do |issue_page|
          issue_page.click_close_issue_button

          expect(issue_page).to have_reopen_issue_button
        end

        Page::Project::Menu.perform(&:go_to_work_items)

        index_page_type.perform do |index|
          expect(index).not_to have_issue(resource)

          index.click_closed_issues_tab

          expect(index).to have_issue(resource)
        end
      end

      # See https://gitlab.com/gitlab-org/gitlab/-/issues/526755
      it(
        'creates an issue and updates the description',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/533855'
      ) do
        resource, _, show_page_type = create_new_issue
        updated_description = "Updated issue description"

        resource.visit!
        show_page_type.perform do |show|
          show.edit_description(updated_description)

          expect(show).to have_description(updated_description)
        end
      end

      context 'when using attachments in comments', :object_storage do
        let(:png_file_name) { 'testfile.png' }
        let(:file_to_attach) { Runtime::Path.fixture('designs', png_file_name) }

        it(
          'comments on an issue with an attachment',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347946'
        ) do
          resource, _, show_page_type = create_new_issue
          resource.visit!
          show_page_type.perform do |show|
            show.comment('See attached image for scale', attachment: file_to_attach)

            expect(show.noteable_note_item.find("img[src$='#{png_file_name}']")).to be_visible
          end
        end
      end

      def create_new_issue
        project.visit!
        Page::Project::Menu.perform(&:go_to_new_issue)
        work_item_view_enabled = Page::Project::Issue::Show.perform(&:work_item_enabled?)

        if work_item_view_enabled
          resource = Resource::WorkItem.fabricate_via_browser_ui! { |work_item| work_item.project = project }
          index_page_type = Page::Project::Issue::Index
          show_page_type = Page::Project::WorkItem::Show
        else
          resource = Resource::Issue.fabricate_via_browser_ui! { |issue| issue.project = project }
          index_page_type = Page::Project::Issue::Index
          show_page_type = Page::Project::Issue::Show
        end

        [resource, index_page_type, show_page_type]
      end
    end
  end
end
