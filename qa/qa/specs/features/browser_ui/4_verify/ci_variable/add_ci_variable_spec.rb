# frozen_string_literal: true

module QA
  context 'Verify' do
    describe 'CI variable support' do
      it 'user adds a CI variable', :smoke do
        Flow::Login.sign_in

        project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-ci-variables'
          project.description = 'project with CI variables'
        end

        Resource::CiVariable.fabricate_via_api! do |resource|
          resource.project = project
          resource.key = 'VARIABLE_KEY'
          resource.value = 'some_CI_variable'
          resource.masked = false
        end

        project.visit!

        Page::Project::Menu.perform(&:go_to_ci_cd_settings)

        Page::Project::Settings::CICD.perform do |settings|
          settings.expand_ci_variables do |page|
            expect(page).to have_field(with: 'VARIABLE_KEY')
            expect(page).not_to have_field(with: 'some_CI_variable')

            page.reveal_variables

            expect(page).to have_field(with: 'some_CI_variable')
          end
        end
      end
    end
  end
end
