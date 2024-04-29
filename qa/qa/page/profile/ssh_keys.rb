# frozen_string_literal: true

module QA
  module Page
    module Profile
      class SSHKeys < Page::Base
        view 'app/views/user_settings/ssh_keys/_form.html.haml' do
          element 'key-title-field'
          element 'key-public-key-field'
          element 'add-key-button'
        end

        view 'app/assets/javascripts/access_tokens/components/expires_at_field.vue' do
          element 'expiry-date-field'
        end

        view 'app/helpers/ssh_keys_helper.rb' do
          element 'delete-ssh-key-button'
          element 'ssh-key-delete-modal'
        end

        view 'app/views/user_settings/ssh_keys/_key_table.html.haml' do
          element 'ssh-keys-list'
        end

        def add_key(public_key, title)
          click_button('Add new key')

          fill_element('key-public-key-field', public_key)
          fill_element('key-title-field', title)
          # Expire in 2 days just in case the key is created just before midnight
          fill_expiry_date(Date.today + 2)
          # Close the datepicker
          find_element('expiry-date-field').find('input').send_keys(:enter)

          click_element('add-key-button')
        end

        def fill_expiry_date(date)
          date = date.iso8601 if date.is_a?(Date)
          begin
            Date.strptime(date, '%Y-%m-%d')
          rescue ArgumentError
            raise "Expiry date must be in YYYY-MM-DD format"
          end

          fill_element('expiry-date-field', date)
        end

        def remove_key(title)
          click_link(title)

          click_element('delete-ssh-key-button')

          # Retrying due to https://gitlab.com/gitlab-org/gitlab/-/issues/255287
          retry_on_exception do
            wait_for_animated_element('ssh-key-delete-modal')
            within_element('ssh-key-delete-modal') do
              click_button('Delete')
            end
          end
        end

        def keys_list
          find_element('ssh-keys-list').text
        end
      end
    end
  end
end
