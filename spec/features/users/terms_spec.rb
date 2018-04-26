require 'spec_helper'

describe 'Users > Terms' do
  let(:user) { create(:user) }
  let!(:term) { create(:term, terms: 'By accepting, you promise to be nice!') }

  before do
    sign_in(user)

    visit terms_path
  end

  it 'shows the terms' do
    expect(page).to have_content('By accepting, you promise to be nice!')
  end
end
