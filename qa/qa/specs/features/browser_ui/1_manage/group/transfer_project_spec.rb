# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Project transfer between groups' do
      let(:source_group) do
        Resource::Group.fabricate_via_api! do |group|
          group.path = 'source-group'
        end
      end

      let(:target_group) do
        Resource::Group.fabricate_via_api! do |group|
          group.path = "target-group-for-transfer_#{SecureRandom.hex(8)}"
        end
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.group = source_group
          project.name = 'transfer-project'
          project.initialize_with_readme = true
        end
      end

      let(:edited_readme_content) { 'Here is the edited content.' }

      before do
        Flow::Login.sign_in

        project.visit!

        Page::Project::Show.perform do |project|
          project.click_file('README.md')
        end

        Page::File::Show.perform(&:click_edit)

        Page::File::Edit.perform do |file|
          file.remove_content
          file.add_content(edited_readme_content)
          file.commit_changes
        end
      end

      it 'user transfers a project between groups',
         testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1703' do
        # Retry is needed here as the target group is not avaliable for transfer right away.
        QA::Support::Retrier.retry_on_exception(reload_page: page) do
          Page::File::Show.perform(&:go_to_general_settings)

          Page::Project::Settings::Main.perform(&:expand_advanced_settings)

          Page::Project::Settings::Advanced.perform do |advanced|
            advanced.transfer_project!(project.name, target_group.full_path)
          end
        end

        Page::Project::Settings::Main.perform(&:click_project)

        Page::Project::Show.perform do |project|
          expect(project).to have_breadcrumb(target_group.path)
          expect(project).to have_readme_content(edited_readme_content)
        end
      end
    end
  end
end
