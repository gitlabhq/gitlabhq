# frozen_string_literal: true

module QA
  context 'Manage', :smoke do
    describe 'basic user login' do
      it 'user logs in using basic credentials and logs out' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        # TODO, since `Signed in successfully` message was removed
        # this is the only way to tell if user is signed in correctly.
        #
        Page::Main::Menu.perform do |menu|
          expect(menu).to have_personal_area
        end

        Page::Main::Menu.perform do |menu|
          menu.sign_out
          expect(menu).not_to have_personal_area
        end

        Page::Main::Login.perform do |form|
          expect(form.sign_in_tab?).to be(true)
        end
      end
    end
  end
end
