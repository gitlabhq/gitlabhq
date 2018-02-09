module QA
  feature 'secret variables support', :core do
    scenario 'user adds a secret variable' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      variable_key = 'VARIABLE_KEY'
      variable_value = 'variable value'

      variable = Factory::Resource::SecretVariable.fabricate! do |resource|
        resource.key = variable_key
        resource.value = variable_value
      end

      expect(variable.key).to eq(variable_key)
      expect(variable.value).to eq(variable_value)
    end
  end
end
