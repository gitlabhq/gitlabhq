module QA
  module Page
    module Profile
      class PersonalAccessTokens < Page::Base
        view 'app/views/shared/_personal_access_tokens_form.html.haml' do
          element :personal_access_token_name_field, 'text_field :name'
          element :create_token_button, 'submit "Create #{type} token"' # rubocop:disable Lint/InterpolationCheck
          element :scopes_api_radios, "label :scopes"
        end

        view 'app/views/profiles/personal_access_tokens/index.html.haml' do
          element :create_token_field, "text_field_tag 'created-personal-access-token'"
        end

        def fill_token_name(name)
          fill_in 'personal_access_token_name', with: name
        end

        def check_api
          check 'personal_access_token_scopes_api'
        end

        def create_token
          click_on 'Create personal access token'
        end

        def created_access_token
          page.find('#created-personal-access-token').value
        end
      end
    end
  end
end
