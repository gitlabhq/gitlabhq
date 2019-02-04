# frozen_string_literal: true

module QA
  module Page
    module Profile
      class SSHKeys < Page::Base
        view 'app/views/profiles/keys/_form.html.haml' do
          element :key_title_field
          element :key_public_key_field
          element :add_key_button
        end

        view 'app/views/profiles/keys/_key_details.html.haml' do
          element :delete_key_button
        end

        def add_key(public_key, title)
          fill_element :key_public_key_field, public_key
          fill_element :key_title_field, title

          click_element :add_key_button
        end

        def remove_key(title)
          click_link(title)

          accept_alert do
            click_element :delete_key_button
          end
        end
      end
    end
  end
end
