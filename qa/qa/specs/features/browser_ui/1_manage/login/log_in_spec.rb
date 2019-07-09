# frozen_string_literal: true

module QA
  context 'Manage', :smoke do
    describe 'basic user login' do
      it 'user logs in using basic credentials and logs out' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        Page::Main::Menu.perform do |menu|
          expect(menu).to have_personal_area
        end

        Support::Retrier.retry_on_exception do
          Page::Main::Menu.perform(&:sign_out)
        end

        Page::Main::Login.perform do |form|
          expect(form.sign_in_tab?).to be(true)
        end
      end
    end
  end
end
