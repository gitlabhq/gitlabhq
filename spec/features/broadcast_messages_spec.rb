# frozen_string_literal: true

require 'spec_helper'

describe 'Broadcast Messages' do
  let!(:broadcast_message) { create(:broadcast_message, broadcast_type: 'notification', message: 'SampleMessage') }

  it 'shows broadcast message' do
    visit root_path

    expect(page).to have_content 'SampleMessage'
  end

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
