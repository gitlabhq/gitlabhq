# frozen_string_literal: true

module QA
  shared_examples 'registration and login' do
    it 'user registers and logs in' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)

      Resource::User.fabricate_via_browser_ui!

      Page::Main::Menu.perform do |menu|
        expect(menu).to have_personal_area
      end
    end
  end

  context 'Manage', :skip_signup_disabled do
    describe 'standard' do
      it_behaves_like 'registration and login'
    end
  end

  context 'Manage', :orchestrated, :ldap_no_tls, :skip_signup_disabled do
    describe 'while LDAP is enabled' do
      it_behaves_like 'registration and login'
    end
  end
end
