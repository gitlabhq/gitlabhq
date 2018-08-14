require 'rails_helper'

describe 'read-only message' do
  set(:user) { create(:user) }

  before do
    sign_in(user)
  end

  it 'shows read-only banner when database is read-only' do
    allow(Gitlab::Database).to receive(:read_only?).and_return(true)

    visit root_dashboard_path

    expect(page).to have_content('You are on a read-only GitLab instance.')
  end

  it 'does not show read-only banner when database is able to read-write' do
    allow(Gitlab::Database).to receive(:read_only?).and_return(false)

    visit root_dashboard_path

    expect(page).not_to have_content('You are on a read-only GitLab instance.')
  end
end
