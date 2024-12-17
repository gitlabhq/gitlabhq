# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'Project transfer', product_group: :tenant_scale do
      let(:project) { create(:project, name: 'transfer-project', group: source_group) }
      let(:source_group) { create(:group, path: "source-group-#{SecureRandom.hex(8)}") }
      let!(:target_group) { create(:group, path: "target-group-for-transfer_#{SecureRandom.hex(8)}") }
      let(:readme_content) { 'Here is the edited content.' }

      before do
        create(:commit, project: project, actions: [
          { action: 'create', file_path: 'README.md', content: readme_content }
        ])

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
