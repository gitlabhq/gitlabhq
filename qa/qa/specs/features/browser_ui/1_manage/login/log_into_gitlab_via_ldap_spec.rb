# frozen_string_literal: true

module QA
  context 'Manage', :orchestrated, :ldap_no_tls, :ldap_tls do
    describe 'LDAP login' do
      it 'user logs into GitLab using LDAP credentials' do
        Flow::Login.sign_in

        Page::Main::Menu.perform do |menu|
          expect(menu).to have_personal_area
        end
      end
    end
  end
end
