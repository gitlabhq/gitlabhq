# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Link to line in Web IDE' do
      let(:user) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1) }
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.template_name = 'express'
        end
      end

      before do
        Flow::Login.sign_in
      end

      after do
        project.remove_via_api!
      end

      it 'can link to a specific line of code in Web IDE', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1102' do
        project.visit!

        Page::Project::Show.perform(&:open_web_ide!)

        Page::Project::WebIDE::Edit.perform do |ide|
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
