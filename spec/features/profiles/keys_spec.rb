require 'rails_helper'

feature 'Profile > SSH Keys', feature: true do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe 'User adds a key' do
    before do
      visit profile_keys_path
    end

    scenario 'auto-populates the title', js: true do
      fill_in('Key', with: attributes_for(:key).fetch(:key))

      expect(find_field('Title').value).to eq 'dummy@gitlab.com'
    end

    scenario 'saves the new key' do
      attrs = attributes_for(:key)

      fill_in('Key', with: attrs[:key])
      fill_in('Title', with: attrs[:title])
      click_button('Add key')

      expect(page).to have_content("Title: #{attrs[:title]}")
      expect(page).to have_content(attrs[:key])
    end
  end

  scenario 'User sees their keys' do
    key = create(:key, user: user)
    visit profile_keys_path

    expect(page).to have_content(key.title)
  end

  scenario 'User removes a key via the key index' do
    create(:key, user: user)
    visit profile_keys_path

    click_link('Remove')

    expect(page).to have_content('Your SSH keys (0)')
  end

  scenario 'User removes a key via its details page' do
    key = create(:key, user: user)
    visit profile_key_path(key)

    click_link('Remove')

    expect(page).to have_content('Your SSH keys (0)')
  end
end
