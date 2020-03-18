# frozen_string_literal: true

require 'spec_helper'

describe 'Broadcast Messages' do
  shared_examples 'a Broadcast Messages' do
    it 'shows broadcast message' do
      visit root_path

      expect(page).to have_content 'SampleMessage'
    end
  end

  shared_examples 'a dismissable Broadcast Messages' do
    it 'hides broadcast message after dismiss', :js do
      visit root_path

      find('.js-dismiss-current-broadcast-notification').click

      expect(page).not_to have_content 'SampleMessage'
    end

    it 'broadcast message is still hidden after refresh', :js do
      visit root_path

      find('.js-dismiss-current-broadcast-notification').click
      visit root_path

      expect(page).not_to have_content 'SampleMessage'
    end
  end

  describe 'banner type' do
    let!(:broadcast_message) { create(:broadcast_message, message: 'SampleMessage') }

    it_behaves_like 'a Broadcast Messages'

    it 'shows broadcast message' do
      visit root_path

      expect(page).not_to have_selector('.js-dismiss-current-broadcast-notification')
    end
  end

  describe 'dismissable banner type' do
    let!(:broadcast_message) { create(:broadcast_message, dismissable: true, message: 'SampleMessage') }

    it_behaves_like 'a Broadcast Messages'

    it_behaves_like 'a dismissable Broadcast Messages'
  end

  describe 'notification type' do
    let!(:broadcast_message) { create(:broadcast_message, broadcast_type: 'notification', message: 'SampleMessage') }

    it_behaves_like 'a Broadcast Messages'

    it_behaves_like 'a dismissable Broadcast Messages'
  end

  it 'renders broadcast message with placeholders' do
    create(:broadcast_message, broadcast_type: 'notification', message: 'Hi {{name}}')

    user = create(:user)
    sign_in(user)

    visit root_path

    expect(page).to have_content "Hi #{user.name}"
  end
end
