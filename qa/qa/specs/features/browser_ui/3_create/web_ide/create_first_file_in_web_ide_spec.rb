# frozen_string_literal: true

module QA
  RSpec.describe 'Create', feature_flag: { name: 'vscode_web_ide', scope: :global }, product_group: :editor do
    describe 'First file using Web IDE' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'empty-project'
          project.initialize_with_readme = false
        end
      end

      let(:file_name) { 'the very first file.txt' }

      before do
        Runtime::Feature.disable(:vscode_web_ide)
        Flow::Login.sign_in
      end

      after do
        Runtime::Feature.enable(:vscode_web_ide)
      end

      it "creates the first file in an empty project via Web IDE", testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347803' do
        project.visit!
        Page::Project::Show.perform(&:create_first_new_file!)

        Page::Project::WebIDE::Edit.perform do |ide|
          ide.wait_until_ide_loads
          ide.create_first_file(file_name)
          ide.commit_changes
        end

        project.visit!

        Page::Project::Show.perform do |project|
          expect(project).to have_file(file_name)
        end
      end
    end
  end
end
