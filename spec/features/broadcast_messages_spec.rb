# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Broadcast Messages' do
  let_it_be(:user) { create(:user) }

  shared_examples 'a Broadcast Messages' do |type|
    it 'shows broadcast message' do
      visit root_path

      expect(page).to have_content 'SampleMessage'
    end

    it 'renders styled links' do
      create(:broadcast_message, type, message: "<a href='gitlab.com' style='color: purple'>click me</a>")

      visit root_path

      expected_html = "<p><a href=\"gitlab.com\" style=\"color: purple\">click me</a></p>"
      expect(page.body).to include(expected_html)
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

    it 'is not dismissable' do
      visit root_path

      expect(page).not_to have_selector('.js-dismiss-current-broadcast-notification')
    end

    it 'does not replace placeholders' do
      create(:broadcast_message, message: 'Hi {{name}}')

      sign_in(user)

      visit root_path

      expect(page).to have_content 'Hi {{name}}'
    end
  end

  describe 'dismissable banner type' do
    let!(:broadcast_message) { create(:broadcast_message, dismissable: true, message: 'SampleMessage') }

    it_behaves_like 'a Broadcast Messages'

    it_behaves_like 'a dismissable Broadcast Messages'
  end

  describe 'notification type' do
    let!(:broadcast_message) { create(:broadcast_message, :notification, message: 'SampleMessage') }

    it_behaves_like 'a Broadcast Messages', :notification

    it_behaves_like 'a dismissable Broadcast Messages'

    it 'replaces placeholders' do
      create(:broadcast_message, :notification, message: 'Hi {{name}}')

      sign_in(user)

      visit root_path

      expect(page).to have_content "Hi #{user.name}"
    end
  end
end
