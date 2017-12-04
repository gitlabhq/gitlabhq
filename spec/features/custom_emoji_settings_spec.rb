require 'spec_helper'

describe 'Custom Emoji settings', :js do
  shared_examples 'Custom Emoji index page' do
    let(:emoji_name) { 'awesome_banana' }
    let(:emoji_file) { File.join(Rails.root, 'spec', 'fixtures', 'banana_sample.gif') }

    before do
      visit custom_emoji_index_path
    end

    it 'can add an emoji' do
      fill_in :custom_emoji_name, with: emoji_name
      attach_file(:custom_emoji_file, emoji_file, visible: false)
      click_button 'Add new emoji'

      expect(page).to have_selector '.js-custom-emoji-table td', text: ":#{emoji_name}:"
    end

    it 'can remove an emoji' do
      create(:custom_emoji, name: emoji_name, namespace: namespace)
      visit custom_emoji_index_path

      find('.js-delete-emoji').click

      expect(page).not_to have_selector '.js-custom-emoji-table tbody tr'
    end

    it 'form is still operational after an error occurs' do
      fill_in :custom_emoji_name, with: 'invalid-emoji-name!@#()'
      click_button 'Add new emoji'

      expect(page).to have_selector '#error_explanation'

      fill_in :custom_emoji_name, with: emoji_name
      attach_file(:custom_emoji_file, emoji_file, visible: false)

      # Ensure the JS still works
      expect(page).to have_selector '.js-choose-file-name', text: 'banana_sample.gif'

      click_button 'Add new emoji'

      expect(page).to have_selector '.js-custom-emoji-table td', text: ":#{emoji_name}:"
    end

    it 'shows error when entering an invalid name' do
      fill_in :custom_emoji_name, with: 'invalid-emoji-name!@#()'
      attach_file(:custom_emoji_file, emoji_file, visible: false)
      click_button 'Add new emoji'

      expect(page).not_to have_selector '.js-custom-emoji-table tbody tr'
      expect(page).to have_selector '#error_explanation'
    end

    it 'shows error when no image file is selected' do
      fill_in :custom_emoji_name, with: emoji_name
      click_button 'Add new emoji'

      expect(page).not_to have_selector '.js-custom-emoji-table tbody tr'
      expect(page).to have_selector '#error_explanation'
    end
  end

  describe 'Group' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }

    before do
      group.add_owner(user)
      sign_in(user)
    end

    it_behaves_like 'Custom Emoji index page' do
      let(:custom_emoji_index_path) { group_settings_custom_emoji_index_path(group) }
      let(:namespace) { group }
    end
  end

  describe 'Profile' do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    it_behaves_like 'Custom Emoji index page' do
      let(:custom_emoji_index_path) { profile_custom_emoji_index_path }
      let(:namespace) { user.namespace }
    end
  end
end
