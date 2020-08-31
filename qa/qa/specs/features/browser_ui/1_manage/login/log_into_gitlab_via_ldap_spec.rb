# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :orchestrated, :ldap_no_tls, :ldap_tls do
    describe 'LDAP login' do
      it 'user logs into GitLab using LDAP credentials', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/668' do
        Flow::Login.sign_in

        Page::Main::Menu.perform do |menu|
          expect(menu).to have_personal_area
        end
      end
    end
  end
end
