# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin impersonates user', feature_category: :user_management do
  let_it_be(:user) { create(:omniauth_user, provider: 'twitter', extern_uid: '123456') }
  let_it_be(:current_user) { create(:admin) }

  before do
    sign_in(current_user)
    enable_admin_mode!(current_user, use_ui: true)
  end

  describe 'GET /admin/users/:id' do
    describe 'Impersonation' do
      let_it_be(:another_user) { create(:user) }

      context 'before impersonating' do
        subject { visit admin_user_path(user_to_visit) }

        let_it_be(:user_to_visit) { another_user }

        shared_examples "user that cannot be impersonated" do
          it 'disables impersonate button' do
            subject

            impersonate_btn = find_by_testid('impersonate-user-link')

            expect(impersonate_btn).not_to be_nil
            expect(impersonate_btn['disabled']).not_to be_nil
          end

          it "shows tooltip with correct error message" do
            subject

            expect(find("span[title='#{impersonation_error_msg}']")).not_to be_nil
          end
        end

        context 'for other users' do
          it 'shows impersonate button for other users' do
            subject

            expect(page).to have_content('Impersonate')
            impersonate_btn = find_by_testid('impersonate-user-link')
            expect(impersonate_btn['disabled']).to be_nil
          end
        end

        context 'for admin itself' do
          let(:user_to_visit) { current_user }

          it 'does not show impersonate button for admin itself' do
            subject

            expect(page).to have_no_content('Impersonate')
          end
        end

        context 'for blocked user' do
          let_it_be(:blocked_user) { create(:user, :blocked) }
          let(:user_to_visit) { blocked_user }
          let(:impersonation_error_msg) { _('You cannot impersonate a blocked user') }

          it_behaves_like "user that cannot be impersonated"
        end

        context 'for user with expired password' do
          let_it_be(:user_to_visit) do
            another_user.update!(password_expires_at: Time.zone.now - 5.minutes)
            another_user
          end

          let(:impersonation_error_msg) { _("You cannot impersonate a user with an expired password") }

          it_behaves_like "user that cannot be impersonated"
        end

        context 'for internal user' do
          let_it_be(:internal_user) { create(:user, :bot) }
          let(:user_to_visit) { internal_user }
          let(:impersonation_error_msg) { _("You cannot impersonate an internal user") }

          it_behaves_like "user that cannot be impersonated"
        end

        context 'for locked user' do
          let_it_be(:locked_user) { create(:user, :locked) }
          let(:user_to_visit) { locked_user }
          let(:impersonation_error_msg) { _("You cannot impersonate a user who cannot log in") }

          it_behaves_like "user that cannot be impersonated"
        end

        context 'when already impersonating another user' do
          let_it_be(:admin_user) { create(:user, :admin) }
          let(:impersonation_error_msg) { _("You are already impersonating another user") }

          subject do
            visit admin_user_path(admin_user)
            click_link 'Impersonate'
            visit admin_user_path(another_user)
          end

          it_behaves_like "user that cannot be impersonated"
        end

        context 'when impersonation is disabled' do
          before do
            stub_config_setting(impersonation_enabled: false)
          end

          it 'does not show impersonate button' do
            subject

            expect(page).to have_no_content('Impersonate')
          end
        end
      end

      context 'when impersonating' do
        subject { click_link 'Impersonate' }

        before do
          visit admin_user_path(another_user)
        end

        it 'logs in as the user when impersonate is clicked', :js do
          subject

          expect(page).to have_button("#{another_user.name} user’s menu")
        end

        it 'sees impersonation log out icon', :js do
          subject

          icon = first('[data-testid="incognito-icon"]')
          expect(icon).not_to be nil
        end

        context 'when viewing the confirm email warning', :js do
          before do
            stub_application_setting_enum('email_confirmation_setting', 'soft')
          end

          let_it_be(:another_user) { create(:user, :unconfirmed) }
          let(:warning_alert) { page.find(:css, '[data-testid="alert-warning"]') }

          context 'with an email that does not contain HTML' do
            before do
              subject
            end

            it 'displays the warning alert including the email' do
              expect(warning_alert.text).to include("Please check your email (#{another_user.email}) to verify")
            end
          end

          context 'with an email that contains HTML' do
            let(:malicious_email) { "malicious@test.com<form><input/title='<script>alert(document.domain)</script>'>" }
            let(:another_user) { create(:user, confirmed_at: nil, unconfirmed_email: malicious_email) }

            before do
              subject
            end

            it 'displays the impersonation alert, excludes email, and disables links' do
              expect(warning_alert.text).to include("check your email (#{another_user.unconfirmed_email}) to verify")
            end
          end
        end
      end

      context 'ending impersonation', :js do
        subject { click_on 'Stop impersonating' }

        before do
          visit admin_user_path(another_user)
          click_link 'Impersonate'
        end

        it 'logs out of impersonated user back to original user' do
          subject

          expect(page).to have_button("#{current_user.name} user’s menu")
        end

        it 'is redirected back to the impersonated users page in the admin after stopping' do
          subject

          expect(page).to have_current_path("/admin/users/#{another_user.username}", ignore_query: true)
        end

        context 'a user with an expired password' do
          before do
            another_user.update!(password_expires_at: Time.zone.now - 5.minutes)
          end

          it 'is redirected back to the impersonated users page in the admin after stopping' do
            subject

            expect(page).to have_current_path("/admin/users/#{another_user.username}", ignore_query: true)
          end
        end
      end
    end
  end
end
