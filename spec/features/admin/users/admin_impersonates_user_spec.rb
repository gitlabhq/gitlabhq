# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin impersonates user', :enable_admin_mode, feature_category: :user_management do
  let_it_be(:user) { create(:omniauth_user, provider: 'twitter', extern_uid: '123456') }
  let_it_be(:current_user) { create(:admin) }

  before do
    sign_in(current_user)
  end

  describe 'GET /admin/users/:id' do
    describe 'Impersonation' do
      let_it_be_with_reload(:another_user) { create(:user) }

      # Warming these caches stops the super sidebar fetching /api/v4/user_counts. That
      # request is what makes the :js examples below flaky.
      #
      # Starting and stopping impersonation both call `warden.set_user`, which rotates the
      # session ID and deletes the old session from Redis; a user counts request in flight
      # across a rotation carries the stale cookie, gets handed a fresh anonymous session,
      # and breaks CSRF on the next request. SidebarsHelper reads the counts with
      # cached_only: true, so a warm cache means no request at all. Both users render the
      # sidebar, so both need warming.
      #
      # See https://gitlab.com/gitlab-org/quality/test-failure-issues/-/work_items/43497.
      def warm_sidebar_counts(*users)
        users.each do |user|
          user.all_assigned_merge_requests_count
          user.review_requested_open_merge_requests_count
        end
      end

      # Reads back what `warm_sidebar_counts` wrote, without computing anything. A nil means
      # the warming stopped working -- a changed cache key, the calls being dropped, or the
      # :use_clean_rails_memory_store_caching tag being removed from a context. Every value
      # must be present, since user_counts.vue fetches when either count is null.
      #
      # One example per context asserts on this as a regression guard, so that a break is
      # reported here rather than as intermittent failures. No behaviour depends on it.
      def sidebar_counts_warmed
        [current_user, another_user].flat_map do |user|
          [
            user.all_assigned_merge_requests_count(cached_only: true),
            user.review_requested_open_merge_requests_count(cached_only: true)
          ]
        end
      end

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

      context 'when impersonating', :use_clean_rails_memory_store_caching do
        subject { click_link 'Impersonate' }

        before do
          warm_sidebar_counts(current_user, another_user)

          visit admin_user_path(another_user)
        end

        it 'logs in as the user when impersonate is clicked', :js, :aggregate_failures do
          expect(sidebar_counts_warmed).not_to include(nil)

          subject

          expect(page).to have_link("#{another_user.name} user’s menu")
        end

        it 'sees impersonation log out icon', :js do
          subject

          icon = first('[data-testid="incognito-icon"]')
          expect(icon).not_to be_nil
        end

        context 'when viewing the confirm email warning', :js do
          before do
            stub_application_setting_enum('email_confirmation_setting', 'soft')
          end

          let_it_be_with_reload(:another_user) { create(:user, :unconfirmed) }
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

      context 'ending impersonation', :js, :use_clean_rails_memory_store_caching do
        before do
          warm_sidebar_counts(current_user, another_user)

          visit admin_user_path(another_user)
          click_link 'Impersonate'
        end

        it "ends impersonating and returns the admin to the impersonated user's page", :aggregate_failures do
          expect(sidebar_counts_warmed).not_to include(nil)

          click_on 'Stop impersonating'

          expect(page).to have_link("#{current_user.name} user’s menu")
          expect(page).to have_current_path("/admin/users/#{another_user.username}", ignore_query: true)
        end
      end
    end
  end
end
