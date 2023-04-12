# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Broadcast Messages', :js, feature_category: :onboarding do
  context 'when creating and editing' do
    it 'previews, creates and edits a broadcast message' do
      admin = create(:admin)
      sign_in(admin)
      gitlab_enable_admin_mode_sign_in(admin)

      # create
      visit admin_broadcast_messages_path

      fill_in 'Message', with: 'test message'

      wait_for_requests

      page.within(preview_container) do
        expect(page).to have_content('test message')
      end

      click_button 'Add broadcast message'

      wait_for_requests

      page.within(preview_container) do
        expect(page).to have_content('Your message here')
      end

      page.within(first_message_container) do
        expect(page).to have_content('test message')
      end

      # edit
      page.within(first_message_container) do
        find('[data-testid="edit-message"]').click
      end

      wait_for_requests

      expect(find('[data-testid="message-input"]').value).to eq('test message')

      fill_in 'Message', with: 'changed test message'

      wait_for_requests

      page.within(preview_container) do
        expect(page).to have_content('changed test message')
      end

      click_button 'Update broadcast message'

      wait_for_requests

      page.within(preview_container) do
        expect(page).to have_content('Your message here')
      end

      page.within(first_message_container) do
        expect(page).to have_content('changed test message')
      end
    end

    def preview_container
      find('[data-testid="preview-broadcast-message"]')
    end

    def first_message_container
      find('[data-testid="message-row"]', match: :first)
    end
  end
end
