# frozen_string_literal: true

module QA
  RSpec.describe 'Create', feature_flag: { name: 'vscode_web_ide', scope: :global }, product_group: :editor do
    describe 'Link to line in Web IDE' do
      let(:user) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1) }
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.template_name = 'express'
        end
      end

      before do
        Runtime::Feature.disable(:vscode_web_ide)
        Flow::Login.sign_in
      end

      after do
        Runtime::Feature.enable(:vscode_web_ide)
        project.remove_via_api!
      end

      it 'can link to a specific line of code in Web IDE', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347676' do
        project.visit!

        # Open Web IDE by using a keyboard shortcut
        Page::Project::Show.perform(&:open_web_ide_via_shortcut)

        Page::Project::WebIDE::Edit.perform do |ide|
          ide.wait_until_ide_loads
          ide.select_file('app.js')
          @link = ide.link_line('26')
        end

        Flow::Login.sign_in(as: user)

        page.visit(@link)

        Page::Project::WebIDE::Edit.perform do |ide|
          expect(ide).to have_file('app.js')
        end

        expect(page.driver.current_url).to include('app.js/#L26')
      end
    end
  end
end
