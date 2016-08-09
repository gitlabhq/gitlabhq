require 'spec_helper'

describe "Admin::AbuseReports", feature: true, js: true  do
  let(:user) { create(:user) }

  context 'as an admin' do
    describe 'if a user has been reported for abuse' do
      before do
        create(:abuse_report, user: user)
        login_as :admin
      end

      describe 'in the abuse report view' do
        it "presents a link to the user's profile" do
          visit admin_abuse_reports_path

          expect(page).to have_link user.name, href: user_path(user)
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
