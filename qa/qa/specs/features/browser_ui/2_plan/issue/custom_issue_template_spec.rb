# frozen_string_literal: true

module QA
  RSpec.describe 'Plan' do
    describe 'Custom issue templates' do
      let(:template_name) { 'custom_issue_template'}
      let(:template_content) { 'This is a custom issue template test' }

      let(:template_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = "custom-issue-template-project"
          project.initialize_with_readme = true
        end
      end

      before do
        Flow::Login.sign_in

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = template_project
          commit.commit_message = 'Add custom issue template'
          commit.add_files([
            {
              file_path: ".gitlab/issue_templates/#{template_name}.md",
              content: template_content
            }
          ])
        end
      end

      it 'creates an issue via custom template', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1229' do
        Resource::Issue.fabricate_via_browser_ui! do |issue|
          issue.project = template_project
          issue.template = template_name
        end

        Page::Project::Issue::Show.perform do |issue_page|
          expect(issue_page).to have_content(template_content)
        end
      end
    end
  end
end
