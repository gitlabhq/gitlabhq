# frozen_string_literal: true

module QA
  context 'Manage', :orchestrated, :ldap_no_tls, :ldap_tls do
    describe 'LDAP login' do
      it 'user logs into GitLab using LDAP credentials' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        # TODO, since `Signed in successfully` message was removed
        # this is the only way to tell if user is signed in correctly.
        #
        Page::Main::Menu.perform do |menu|
          expect(menu).to have_personal_area
        end
      end
    end
  end
end
