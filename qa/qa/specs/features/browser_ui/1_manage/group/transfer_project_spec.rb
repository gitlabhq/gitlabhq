# frozen_string_literal: true

module QA
  context 'Manage' do
    describe 'Project transfer between groups' do
      it 'user transfers a project between groups' do
        Flow::Login.sign_in

        source_group = Resource::Group.fabricate_via_api! do |group|
          group.path = 'source-group'
        end

        target_group = Resource::Group.fabricate_via_api! do |group|
          group.path = 'target-group'
        end

        project = Resource::Project.fabricate_via_api! do |project|
          project.group = source_group
          project.name =  'transfer-project'
          project.initialize_with_readme = true
        end

        project.visit!

        Page::Project::Show.perform do |project|
          project.click_file('README.md')
        end

        Page::File::Show.perform(&:click_edit)

        edited_readme_content = 'Here is the edited content.'

        Page::File::Edit.perform do |file|
          file.remove_content
          file.add_content(edited_readme_content)
          file.commit_changes
        end

        Page::File::Show.perform(&:go_to_general_settings)

        Page::Project::Settings::Main.perform(&:expand_advanced_settings)

        Page::Project::Settings::Advanced.perform do |advanced|
          advanced.transfer_project!(project.name, target_group.full_path)
        end

        Page::Project::Settings::Main.perform(&:click_project)

        Page::Project::Show.perform do |project|
          expect(project).to have_text(target_group.path)
          expect(project).to have_text(edited_readme_content)
        end
      end
    end
  end
end
