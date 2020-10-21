# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'First file using Web IDE' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'empty-project'
          project.initialize_with_readme = false
        end
      end

      let(:file_name) { 'the very first file.txt' }

      before do
        Flow::Login.sign_in
      end

      it "creates the first file in an empty project via Web IDE", testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/847' do
        project.visit!
        Page::Project::Show.perform(&:create_first_new_file!)

        Page::Project::WebIDE::Edit.perform do |ide|
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
