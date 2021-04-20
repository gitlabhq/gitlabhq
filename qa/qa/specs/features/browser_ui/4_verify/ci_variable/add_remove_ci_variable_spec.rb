# frozen_string_literal: true

module QA
  RSpec.describe 'Verify' do
    describe 'Add or Remove CI variable via UI', :smoke do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-ci-variables'
          project.description = 'project with CI variables'
        end
      end

      before do
        Flow::Login.sign_in
        project.visit!
        add_ci_variable
      end

      it 'user adds a CI variable', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1759' do
        Page::Project::Settings::CiVariables.perform do |ci_variable|
          expect(ci_variable).to have_text('VARIABLE_KEY')
          expect(ci_variable).not_to have_text('some_CI_variable')

          ci_variable.click_reveal_ci_variable_value_button

          expect(ci_variable).to have_text('some_CI_variable')
        end
      end

      it 'user removes a CI variable', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1758' do
        Page::Project::Settings::CiVariables.perform do |ci_variable|
          ci_variable.click_edit_ci_variable
          ci_variable.click_ci_variable_delete_button

          expect(ci_variable).to have_text('There are no variables yet', wait: 60)
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
    end
  end
end
