# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Overview
        module Users
          class Show < QA::Page::Base
            view 'app/views/admin/users/_head.html.haml' do
              element 'impersonate-user-link'
              element 'impersonation-tokens-tab'
            end

            view 'app/views/admin/users/show.html.haml' do
              element 'user-id-content'
            end

            view 'app/assets/javascripts/admin/users/components/actions/approve.vue' do
              element 'approve-user-confirm-button'
            end

            view 'app/assets/javascripts/admin/users/components/user_actions.vue' do
              element 'user-actions-dropdown-toggle'
            end

            view 'app/helpers/users_helper.rb' do
              element 'confirm-user-button'
              element 'confirm-user-confirm-button'
            end

            def open_user_actions_dropdown(user)
              click_element('user-actions-dropdown-toggle', username: user.username)
            end

            def go_to_impersonation_tokens(&block)
              navigate_to_tab('impersonation-tokens-tab')
              Users::Components::ImpersonationTokens.perform(&block)
            end

            def click_impersonate_user
              click_element('impersonate-user-link')
            end

            def user_id
              find_element('user-id-content').text
            end

            def confirm_user
              click_element 'confirm-user-button'
              click_element 'confirm-user-confirm-button'
            end

            def approve_user(user)
              open_user_actions_dropdown(user)
              click_element 'approve'
              click_element 'approve-user-confirm-button'
            end

            private

            def navigate_to_tab(element_name)
              wait_until(reload: false) do
                click_element element_name unless on_impersontation_tokens_tab?

                on_impersontation_tokens_tab?(wait: 10)
              end
            end

            def on_impersontation_tokens_tab?(wait: 1)
              has_css?(".active", text: 'Impersonation Tokens', wait: wait)
            end
          end
        end
      end
    end
  end
end
