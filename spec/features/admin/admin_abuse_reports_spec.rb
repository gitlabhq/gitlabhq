# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin::AbuseReports", :js do
  let(:user) { create(:user) }

  context 'as an admin' do
    before do
      admin = create(:admin)
      sign_in(admin)
      gitlab_enable_admin_mode_sign_in(admin)
    end

    describe 'if a user has been reported for abuse' do
      let!(:abuse_report) { create(:abuse_report, user: user) }

      describe 'in the abuse report view' do
        it 'presents information about abuse report' do
          visit admin_abuse_reports_path

          expect(page).to have_content('Abuse Reports')
          expect(page).to have_content(abuse_report.message)
          expect(page).to have_link(user.name, href: user_path(user))
          expect(page).to have_link('Remove user')
        end
      end

      describe 'in the profile page of the user' do
        it 'shows a link to the admin view of the user' do
          visit user_path(user)

          expect(page).to have_link '', href: admin_user_path(user)
        end
      end
    end

    describe 'if a many users have been reported for abuse' do
      let(:report_count) { AbuseReport.default_per_page + 3 }

      before do
        report_count.times do
          create(:abuse_report, user: create(:user))
        end
      end

      describe 'in the abuse report view' do
        it 'presents information about abuse report' do
          visit admin_abuse_reports_path

          expect(page).to have_selector('.pagination')
          expect(page).to have_selector('.pagination .js-pagination-page', count: (report_count.to_f / AbuseReport.default_per_page).ceil)
        end
      end
    end

    describe 'filtering by user' do
      let!(:user2) { create(:user) }
      let!(:abuse_report) { create(:abuse_report, user: user) }
      let!(:abuse_report_2) { create(:abuse_report, user: user2) }

      it 'shows only single user report' do
        visit admin_abuse_reports_path

        page.within '.filter-form' do
          click_button 'User'
          wait_for_requests

          page.within '.dropdown-menu-user' do
            click_link user2.name
          end

          wait_for_requests
        end

        expect(page).to have_content(user2.name)
        expect(page).not_to have_content(user.name)
      end
    end
  end
end
