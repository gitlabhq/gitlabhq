class Spinach::Features::AdminBroadcastMessages < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  step 'application already has a broadcast message' do
    FactoryGirl.create(:broadcast_message, :expired, message: "Migration to new server")
  end

  step 'I should see all broadcast messages' do
    expect(page).to have_content "Migration to new server"
  end

  step 'I should be redirected to admin messages page' do
    expect(current_path).to eq admin_broadcast_messages_path
  end

  step 'I should see newly created broadcast message' do
    expect(page).to have_content 'Application update from 4:00 CST to 5:00 CST'
  end

  step 'submit form with new customized broadcast message' do
    fill_in 'broadcast_message_message', with: 'Application update from **4:00 CST to 5:00 CST**'
    fill_in 'broadcast_message_color', with: '#f2dede'
    fill_in 'broadcast_message_font', with: '#b94a48'
    select Date.today.next_year.year, from: "broadcast_message_ends_at_1i"
    click_button "Add broadcast message"
  end

  step 'I should see a customized broadcast message' do
    expect(page).to have_content 'Application update from 4:00 CST to 5:00 CST'
    expect(page).to have_selector 'strong', text: '4:00 CST to 5:00 CST'
    expect(page).to have_selector %(div[style="background-color: #f2dede; color: #b94a48"])
  end

  step 'I edit an existing broadcast message' do
    click_link 'Edit'
  end

  step 'I change the broadcast message text' do
    fill_in 'broadcast_message_message', with: 'Application update RIGHT NOW'
    click_button 'Update broadcast message'
  end

  step 'I should see the updated broadcast message' do
    expect(page).to have_content "Application update RIGHT NOW"
  end

  step 'I remove an existing broadcast message' do
    click_link 'Remove'
  end

  step 'I should not see the removed broadcast message' do
    expect(page).not_to have_content 'Migration to new server'
  end

  step 'I enter a broadcast message with Markdown' do
    fill_in 'broadcast_message_message', with: "Live **Markdown** previews. :tada:"
  end

  step 'I should see a live preview of the rendered broadcast message' do
    page.within('.broadcast-message-preview') do
      expect(page).to have_selector('strong', text: 'Markdown')
      expect(page).to have_selector('img.emoji')
    end
  end
end
