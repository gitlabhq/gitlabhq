# frozen_string_literal: true

module QA
  context 'Verify' do
    describe 'CI variable support' do
      it 'user adds a CI variable' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        Resource::CiVariable.fabricate! do |resource|
          resource.key = 'VARIABLE_KEY'
          resource.value = 'some CI variable'
        end

        Page::Project::Settings::CICD.perform do |settings|
          settings.expand_ci_variables do |page|
            expect(page).to have_field(with: 'VARIABLE_KEY')
            expect(page).not_to have_field(with: 'some CI variable')

            page.reveal_variables

            expect(page).to have_field(with: 'some CI variable')
          end
        end
      end
    end
  end
end
