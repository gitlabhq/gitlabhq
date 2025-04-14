# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', product_group: :project_management do
    describe 'Custom issue templates' do
      let(:template_name) { 'custom_issue_template' }
      let(:template_content) { 'This is a custom issue template test' }

      let(:template_project) do
        create(:project, :with_readme, name: 'custom-issue-template-project')
      end

      before do
        Flow::Login.sign_in

        create(:commit, project: template_project, commit_message: 'Add custom issue template', actions: [
          { action: 'create', file_path: ".gitlab/issue_templates/#{template_name}.md", content: template_content }
        ])
      end

      it 'creates an issue via custom template', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347945' do
        template_project.visit!
        Page::Project::Menu.perform(&:go_to_new_issue)

        work_item_enabled = Page::Project::Issue::Show.perform(&:work_item_enabled?)
        show_page_type = work_item_enabled ? Page::Project::WorkItem::Show : Page::Project::Issue::Show
        resource_type = work_item_enabled ? Resource::WorkItem : Resource::Issue

        resource_type.fabricate_via_browser_ui! do |issue|
          issue.project = template_project
          issue.template = template_name
        end

        show_page_type.perform do |issue_page|
          expect(issue_page).to have_content(template_content)
        end
      end
    end
  end
end
