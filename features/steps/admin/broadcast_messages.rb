class Spinach::Features::AdminBroadcastMessages < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin

  step 'application already has admin messages' do
    FactoryGirl.create(:broadcast_message, message: "Migration to new server")
  end

  step 'I should be all broadcast messages' do
    page.should have_content "Migration to new server"
  end

  step 'submit form with new broadcast message' do
    fill_in 'broadcast_message_message', with: 'Application update from 4:00 CST to 5:00 CST'
    select '2018', from: "broadcast_message_ends_at_1i"
    click_button "Add broadcast message"
  end

  step 'I should be redirected to admin messages page' do
    current_path.should == admin_broadcast_messages_path
  end

  step 'I should see newly created broadcast message' do
    page.should have_content 'Application update from 4:00 CST to 5:00 CST'
  end

  step 'submit form with new customized broadcast message' do
    fill_in 'broadcast_message_message', with: 'Application update from 4:00 CST to 5:00 CST'
    click_link "Customize colors"
    fill_in 'broadcast_message_color', with: '#f2dede'
    fill_in 'broadcast_message_font', with: '#b94a48'
    select '2018', from: "broadcast_message_ends_at_1i"
    click_button "Add broadcast message"
  end

  step 'I should see a customized broadcast message' do
    page.should have_content 'Application update from 4:00 CST to 5:00 CST'
    page.should have_selector %(div[style="background-color:#f2dede;color:#b94a48"])
  end
end
