# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :remote_development, feature_category: :web_ide do
    describe 'Closing Web IDE' do
      include_context "Web IDE test prep"
      let(:file_name) { 'file.txt' }
      let(:project) { create(:project, :with_readme, name: 'webide-close-with-unsaved-changes') }

      before do
        load_web_ide
      end

      it 'shows an alert when there are unsaved changes',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/411298' do
        Page::Project::WebIDE::VSCode.perform do |ide|
          ide.create_new_file(file_name)
          Support::Waiter.wait_until { ide.has_pending_changes? }

          ide.close_ide_tab
          expect do
            ide.ide_tab_closed?
          end.to raise_error(Selenium::WebDriver::Error::UnexpectedAlertOpenError, /unexpected alert open/)
        end
      end
    end
  end
end
