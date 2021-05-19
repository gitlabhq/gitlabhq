# frozen_string_literal: true

module QA
  module Page
    module Profile
      class Menu < Page::Base
        view 'app/views/layouts/nav/sidebar/_profile.html.haml' do
          element :access_token_link, 'link_to profile_personal_access_tokens_path' # rubocop:disable QA/ElementWithPattern
          element :access_token_title, 'Access Tokens' # rubocop:disable QA/ElementWithPattern
          element :top_level_items, '.sidebar-top-level-items' # rubocop:disable QA/ElementWithPattern
          element :ssh_keys, 'SSH Keys' # rubocop:disable QA/ElementWithPattern
          element :profile_emails_link
          element :profile_password_link
          element :profile_account_link
        end

        def click_access_tokens
          within_sidebar do
            click_link('Access Tokens')
          end
        end

        def click_ssh_keys
          within_sidebar do
            click_link('SSH Keys')
          end
        end

        def click_account
          within_sidebar do
            click_element(:profile_account_link)
          end
        end

        def click_emails
          within_sidebar do
            click_element(:profile_emails_link)
          end
        end

        def click_password
          within_sidebar do
            click_element(:profile_password_link)
          end
        end

        private

        def within_sidebar
          page.within('.sidebar-top-level-items') do
            yield
          end
        end
      end
    end
  end
end

QA::Page::Profile::Menu.prepend_mod_with('Page::Profile::Menu', namespace: QA)
