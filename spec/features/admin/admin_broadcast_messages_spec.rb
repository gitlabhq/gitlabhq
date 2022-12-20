# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Broadcast Messages', feature_category: :onboarding do
  before do
    admin = create(:admin)
    sign_in(admin)
    stub_feature_flags(vue_broadcast_messages: false)
    gitlab_enable_admin_mode_sign_in(admin)
    create(
      :broadcast_message,
      :expired,
      message: 'Migration to new server',
      target_access_levels: [Gitlab::Access::DEVELOPER]
    )
    visit admin_broadcast_messages_path
  end

  it 'see broadcast messages list' do
    expect(page).to have_content 'Migration to new server'
  end

  it 'creates a customized broadcast banner message' do
    fill_in 'broadcast_message_message', with: 'Application update from **4:00 CST to 5:00 CST**'
    fill_in 'broadcast_message_target_path', with: '*/user_onboarded'
    select 'light-indigo', from: 'broadcast_message_theme'
    select Date.today.next_year.year, from: 'broadcast_message_ends_at_1i'
    check 'Guest'
    check 'Owner'
    click_button 'Add broadcast message'

    expect(page).to have_current_path admin_broadcast_messages_path, ignore_query: true
    expect(page).to have_content 'Application update from 4:00 CST to 5:00 CST'
    expect(page).to have_content 'Guest, Owner'
    expect(page).to have_content '*/user_onboarded'
    expect(page).to have_selector 'strong', text: '4:00 CST to 5:00 CST'
    expect(page).to have_selector %(.light-indigo[role=alert])
  end

  it 'creates a customized broadcast notification message' do
    fill_in 'broadcast_message_message', with: 'Application update from **4:00 CST to 5:00 CST**'
    fill_in 'broadcast_message_target_path', with: '*/user_onboarded'
    select 'Notification', from: 'broadcast_message_broadcast_type'
    select Date.today.next_year.year, from: 'broadcast_message_ends_at_1i'
    check 'Reporter'
    check 'Developer'
    check 'Maintainer'
    click_button 'Add broadcast message'

    expect(page).to have_current_path admin_broadcast_messages_path, ignore_query: true
    expect(page).to have_content 'Application update from 4:00 CST to 5:00 CST'
    expect(page).to have_content 'Reporter, Developer, Maintainer'
    expect(page).to have_content '*/user_onboarded'
    expect(page).to have_content 'Notification'
    expect(page).to have_selector 'strong', text: '4:00 CST to 5:00 CST'
  end

  it 'edit an existing broadcast message' do
    click_link 'Edit'
    fill_in 'broadcast_message_message', with: 'Application update RIGHT NOW'
    check 'Reporter'
    click_button 'Update broadcast message'

    expect(page).to have_current_path admin_broadcast_messages_path, ignore_query: true
    expect(page).to have_content 'Application update RIGHT NOW'

    page.within('.table-responsive') do
      expect(page).to have_content 'Reporter, Developer'
    end
  end

  it 'remove an existing broadcast message' do
    click_link 'Remove'

    expect(page).to have_current_path admin_broadcast_messages_path, ignore_query: true
    expect(page).not_to have_content 'Migration to new server'
  end

  it 'updates a preview of a customized broadcast banner message', :js do
    fill_in 'broadcast_message_message', with: "Live **Markdown** previews. :tada:"

    page.within('.js-broadcast-banner-message-preview') do
      expect(page).to have_selector('strong', text: 'Markdown')
      expect(page).to have_emoji('tada')
    end
  end

  it 'updates a preview of a customized broadcast notification message', :js do
    fill_in 'broadcast_message_message', with: "Live **Markdown** previews. :tada:"
    select 'Notification', from: 'broadcast_message_broadcast_type'

    page.within('#broadcast-message-preview') do
      expect(page).to have_selector('strong', text: 'Markdown')
      expect(page).to have_emoji('tada')
    end
  end
end
