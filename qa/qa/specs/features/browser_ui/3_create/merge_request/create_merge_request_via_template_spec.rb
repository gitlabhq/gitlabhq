# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Merge request custom templates' do
      let(:template_name) { 'custom_merge_request_template'}
      let(:template_content) { 'This is a custom merge request template test' }
      let(:template_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'custom-mr-template-project'
          project.initialize_with_readme = true
        end
      end

      let(:merge_request_title) { 'One merge request to rule them all' }

      before do
        Flow::Login.sign_in

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = template_project
          commit.commit_message = 'Add custom merge request template'
          commit.add_files([
            {
              file_path: ".gitlab/merge_request_templates/#{template_name}.md",
              content: template_content
            }
          ])
        end
      end

      it 'creates a merge request via custom template', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1230' do
        Resource::MergeRequest.fabricate_via_browser_ui! do |merge_request|
          merge_request.project = template_project
          merge_request.title = merge_request_title
          merge_request.template = template_name
          merge_request.target_new_branch = false
        end

        Page::MergeRequest::Show.perform do |merge_request|
          expect(merge_request).to have_title(merge_request_title)
          expect(merge_request).to have_description(template_content)
        end
      end
    end
  end
end
