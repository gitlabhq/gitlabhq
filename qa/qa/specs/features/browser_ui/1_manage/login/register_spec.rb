# frozen_string_literal: true

module QA
  RSpec.shared_examples 'registration and login' do
    it 'allows the user to registers and login' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)

      Resource::User.fabricate_via_browser_ui!

      Page::Main::Menu.perform do |menu|
        expect(menu).to have_personal_area
      end
    end
  end

  RSpec.describe 'Manage', :skip_signup_disabled do
    describe 'standard' do
      it_behaves_like 'registration and login'

      context 'when user account is deleted', :requires_admin do
        let(:user) do
          Resource::User.fabricate_via_api! do |resource|
            resource.api_client = admin_api_client
          end
        end

        before do
          # Use the UI instead of API to delete the account since
          # this is the only test that exercise this UI.
          # Other tests should use the API for this purpose.
          Flow::Login.sign_in(as: user)
          Page::Main::Menu.perform(&:click_settings_link)
          Page::Profile::Menu.perform(&:click_account)
          Page::Profile::Accounts::Show.perform do |show|
            show.delete_account(user.password)
          end
        end

        it 'allows recreating with same credentials' do
          expect(Page::Main::Menu.perform(&:signed_in?)).to be_falsy

          Flow::Login.sign_in(as: user, skip_page_validation: true)

          expect(page).to have_text("Invalid Login or password")

          @recreated_user = Resource::User.fabricate_via_browser_ui! do |resource|
            resource.name = user.name
            resource.username = user.username
            resource.email = user.email
          end

          expect(Page::Main::Menu.perform(&:signed_in?)).to be_truthy
        end

        after do
          @recreated_user.remove_via_api!
        end

        def admin_api_client
          @admin_api_client ||= Runtime::API::Client.as_admin
        end
      end
    end
  end

  RSpec.describe 'Manage', :orchestrated, :ldap_no_tls, :skip_signup_disabled do
    describe 'while LDAP is enabled' do
      it_behaves_like 'registration and login'
    end
  end
end
