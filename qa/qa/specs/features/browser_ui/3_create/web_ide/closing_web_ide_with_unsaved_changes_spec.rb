# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :ide do
    describe 'Closing Web IDE' do
      let(:file_name) { 'file.txt' }
      let(:project) { create(:project, :with_readme, name: 'webide-close-with-unsaved-changes') }

      before do
        Flow::Login.sign_in
        project.visit!
        Page::Project::Show.perform(&:open_web_ide!)
        Page::Project::WebIDE::VSCode.perform(&:wait_for_ide_to_load)
      end

      it 'shows an alert when there are unsaved changes',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/411298' do
        Page::Project::WebIDE::VSCode.perform do |ide|
          ide.create_new_file(file_name)
          ide.has_file?(file_name)
          ide.close_ide_tab
          expect do
            ide.ide_tab_closed?
          end.to raise_error(Selenium::WebDriver::Error::UnexpectedAlertOpenError, /unexpected alert open/)
        end
      end
    end
  end
end
