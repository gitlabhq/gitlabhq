require 'spec_helper'

describe "Admin::AbuseReports", feature: true, js: true  do
  let(:user) { create(:user) }

  context 'as an admin' do
    before do
      login_as :admin
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
  end
end
