# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'First file using Web IDE' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'empty-project'
          project.initialize_with_readme = false
        end
      end

      let(:web_ide_url) { current_url + '-/ide/project/' + project.path_with_namespace }
      let(:file_name) { 'the very first file.txt' }

      before do
        Flow::Login.sign_in
      end

      it "creates the first file in an empty project via Web IDE" do
        # In the first iteration, the test opens Web IDE by modifying the URL to address past regressions.
        # Once the Web IDE button is introduced for empty projects, the test will be modified to go through UI.
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/27915 and https://gitlab.com/gitlab-org/gitlab/-/issues/27535.
        page.visit(web_ide_url)

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
