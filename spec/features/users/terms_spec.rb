require 'spec_helper'

describe 'Users > Terms' do
  let(:user) { create(:user) }
  let!(:term) { create(:term, terms: 'By accepting, you promise to be nice!') }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(user)
  end

  it 'shows the terms' do
    visit terms_path

    expect(page).to have_content('By accepting, you promise to be nice!')
  end

  context 'declining the terms' do
    it 'returns the user to the app' do
      visit terms_path

      click_button 'Decline and sign out'

      expect(page).not_to have_content(term.terms)
      expect(user.reload.terms_accepted?).to be(false)
    end
  end

  context 'accepting the terms' do
    it 'returns the user to the app' do
      visit terms_path

      click_button 'Accept terms'

      expect(page).not_to have_content(term.terms)
      expect(user.reload.terms_accepted?).to be(true)
    end
  end
end
