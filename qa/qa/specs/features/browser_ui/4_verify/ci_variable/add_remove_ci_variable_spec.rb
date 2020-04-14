# frozen_string_literal: true

module QA
  context 'Verify' do
    describe 'Add or Remove CI variable via UI', :smoke do
      let!(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-ci-variables'
          project.description = 'project with CI variables'
        end
      end

      before(:all) do
        Runtime::Feature.enable_and_verify('new_variables_ui')
      end

      after(:all) do
        Runtime::Feature.remove('new_variables_ui')
      end

      before do
        Flow::Login.sign_in
        add_ci_variable
        open_ci_cd_settings
      end

      it 'user adds a CI variable' do
        Page::Project::Settings::CICD.perform do |settings|
          settings.expand_ci_variables do |page|
            expect(page).to have_text('VARIABLE_KEY')
            expect(page).not_to have_text('some_CI_variable')

            page.click_reveal_ci_variable_value_button

            expect(page).to have_text('some_CI_variable')
          end
        end
      end

      it 'user removes a CI variable' do
        Page::Project::Settings::CICD.perform do |settings|
          settings.expand_ci_variables do |page|
            page.click_edit_ci_variable
            page.click_ci_variable_delete_button

            expect(page).not_to have_text('VARIABLE_KEY')
          end
        end
      end

      private

      def add_ci_variable
        Resource::CiVariable.fabricate_via_browser_ui! do |ci_variable|
          ci_variable.project = project
          ci_variable.key = 'VARIABLE_KEY'
          ci_variable.value = 'some_CI_variable'
          ci_variable.masked = false
        end
      end

      def open_ci_cd_settings
        project.visit!
        Page::Project::Menu.perform(&:go_to_ci_cd_settings)
      end
    end
  end
end
