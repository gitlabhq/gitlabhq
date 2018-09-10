# frozen_string_literal: true

module QA
  context 'Framework sanity checks', :orchestrated, :framework do
    describe 'Passing orchestrated example' do
      it 'succeeds' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        Page::Main::Login.perform do |main_login|
          expect(main_login.sign_in_tab?).to be(true)
        end
      end
    end

    describe 'Failing orchestrated example' do
      it 'fails' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        expect(page).to have_text("These Aren't the Texts You're Looking For", wait: 1)
      end
    end
  end
end
