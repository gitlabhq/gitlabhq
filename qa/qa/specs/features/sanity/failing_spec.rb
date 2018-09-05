# frozen_string_literal: true

module QA
  context 'Sanity checks', :orchestrated, :failing do
    describe 'Failing orchestrated example' do
      it 'always fails' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        expect(page).to have_text("These Aren't the Texts You're Looking For", wait: 1)
      end
    end
  end
end
