# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :code_review do
    describe 'Merge request custom templates' do
      let(:template_name) { 'custom_merge_request_template' }
      let(:template_content) { 'This is a custom merge request template test' }
      let(:template_project) { create(:project, :with_readme, name: 'custom-mr-template-project') }
      let(:merge_request_title) { 'One merge request to rule them all' }

      before do
        Flow::Login.sign_in

        create(:commit, project: template_project, commit_message: 'Add custom merge request template', actions: [
          {
            action: 'create',
            file_path: ".gitlab/merge_request_templates/#{template_name}.md",
            content: template_content
          }
        ])
      end

      it 'creates a merge request via custom template', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347722' do
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
