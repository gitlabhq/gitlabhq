class Spinach::Features::User < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedUser
  include SharedProject

  step 'I should see user "John Doe" page' do
    expect(page.title).to match(/^\s*John Doe/)
  end

  step 'I visit unsubscribe link' do
    email = Base64.urlsafe_encode64("joh@doe.org")
    visit "/unsubscribes/#{email}"
  end

  step 'I should see unsubscribe text and button' do
    page.should have_content "Unsubscribe from Admin notifications Yes, I want to unsubscribe joh@doe.org from any further admin emails."
  end

  step 'I press the unsubscribe button' do
    click_button("Unsubscribe")
  end

  step 'I should be unsubscribed' do
    current_path.should == root_path
  end
end
