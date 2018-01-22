module QA
  feature 'secret variables support', :core do
    given(:variable_key) { 'VARIABLE_KEY' }
    given(:variable_value) { 'variable value' }

    scenario 'user adds a secret variable' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      variable = Factory::Resource::SecretVariable.fabricate! do |resource|
        resource.key = variable_key
        resource.value = variable_value
      end

      expect(variable.key).to eq(variable_key)
      expect(variable.value).to eq(variable_value)
    end
  end
end
