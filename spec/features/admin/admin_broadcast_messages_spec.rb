# frozen_string_literal: true

require 'spec_helper'

describe 'Admin Broadcast Messages' do
  before do
    sign_in(create(:admin))
    create(:broadcast_message, :expired, message: 'Migration to new server')
    visit admin_broadcast_messages_path
  end

  it 'See broadcast messages list' do
    expect(page).to have_content 'Migration to new server'
  end

  it 'Create a customized broadcast message' do
    fill_in 'broadcast_message_message', with: 'Application update from **4:00 CST to 5:00 CST**'
    fill_in 'broadcast_message_color', with: '#f2dede'
    fill_in 'broadcast_message_target_path', with: '*/user_onboarded'
    fill_in 'broadcast_message_font', with: '#b94a48'
    select Date.today.next_year.year, from: 'broadcast_message_ends_at_1i'
    click_button 'Add broadcast message'

    expect(current_path).to eq admin_broadcast_messages_path
    expect(page).to have_content 'Application update from 4:00 CST to 5:00 CST'
    expect(page).to have_content '*/user_onboarded'
    expect(page).to have_selector 'strong', text: '4:00 CST to 5:00 CST'
    expect(page).to have_selector %(div[style="background-color: #f2dede; color: #b94a48"])
  end

  it 'Edit an existing broadcast message' do
    click_link 'Edit'
    fill_in 'broadcast_message_message', with: 'Application update RIGHT NOW'
    click_button 'Update broadcast message'

    expect(current_path).to eq admin_broadcast_messages_path
    expect(page).to have_content 'Application update RIGHT NOW'
  end

  it 'Remove an existing broadcast message' do
    click_link 'Remove'

    expect(current_path).to eq admin_broadcast_messages_path
    expect(page).not_to have_content 'Migration to new server'
  end

  it 'Live preview a customized broadcast message', :js do
    fill_in 'broadcast_message_message', with: "Live **Markdown** previews. :tada:"

    page.within('.broadcast-message-preview') do
      expect(page).to have_selector('strong', text: 'Markdown')
      expect(page).to have_emoji('tada')
    end
  end
end
