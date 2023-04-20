# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'Project transfer between groups', :reliable, product_group: :tenant_scale do
      let(:source_group) do
        Resource::Group.fabricate_via_api! do |group|
          group.path = "source-group-#{SecureRandom.hex(8)}"
        end
      end

      let!(:target_group) do
        Resource::Group.fabricate_via_api! do |group|
          group.path = "target-group-for-transfer_#{SecureRandom.hex(8)}"
        end
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.group = source_group
          project.name = 'transfer-project'
        end
      end

      let(:readme_content) { 'Here is the edited content.' }

      before do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.add_files([{ file_path: 'README.md', content: readme_content }])
        end

        Flow::Login.sign_in

        project.visit!
      end

      it 'user transfers a project between groups',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347878' do
        Page::Project::Menu.perform(&:go_to_general_settings)

        Page::Project::Settings::Main.perform(&:expand_advanced_settings)

        Page::Project::Settings::Advanced.perform do |advanced|
          advanced.transfer_project!(project.name, target_group.full_path)
        end

        Page::Project::Menu.perform(&:click_project)

        Page::Project::Show.perform do |project|
          expect(project).to have_breadcrumb(target_group.path)
          expect(project).to have_readme_content(readme_content)
        end
      end
    end
  end
end
