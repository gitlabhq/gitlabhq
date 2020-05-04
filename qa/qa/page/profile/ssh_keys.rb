# frozen_string_literal: true

module QA
  module Page
    module Profile
      class SSHKeys < Page::Base
        view 'app/views/profiles/keys/_form.html.haml' do
          element :key_expiry_date_field
          element :key_title_field
          element :key_public_key_field
          element :add_key_button
        end

        view 'app/views/profiles/keys/_key_details.html.haml' do
          element :delete_key_button
        end

        view 'app/views/profiles/keys/_key_table.html.haml' do
          element :ssh_keys_list
        end

        def add_key(public_key, title)
          fill_element(:key_public_key_field, public_key)
          fill_element(:key_title_field, title)
          # Expire in 2 days just in case the key is created just before midnight
          fill_expiry_date(Date.today + 2)

          click_element(:add_key_button)
        end

        def fill_expiry_date(date)
          date = date.strftime('%m/%d/%Y') if date.is_a?(Date)
          Date.strptime(date, '%m/%d/%Y') rescue ArgumentError raise "Expiry date must be in mm/dd/yyyy format"

          fill_element(:key_expiry_date_field, date)
        end

        def remove_key(title)
          click_link(title)

          accept_alert do
            click_element(:delete_key_button)
          end
        end

        def keys_list
          find_element(:ssh_keys_list).text
        end
      end
    end
  end
end
