module QA
  module Page
    module Menu
      class Profile < Page::Base
        view 'app/views/layouts/nav/sidebar/_profile.html.haml' do
          element :access_token_link, 'link_to profile_personal_access_tokens_path'
          element :access_token_title, 'Access Tokens'
          element :top_level_items, '.sidebar-top-level-items'
          element :ssh_keys, 'SSH Keys'
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
