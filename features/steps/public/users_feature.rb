class Spinach::Features::PublicUsersFeature < Spinach::FeatureSteps
  include SharedPaths

  step 'user "John Smith"' do
    create(:user, name: 'John Smith', email: 'john.smith@mail.com')
  end

  step 'user "Mary Jane"' do
    create(:user, name: 'Mary Jane', email: 'mary.jane@mail.com')
  end

  step 'I should see user "John Smith"' do
    expect(page).to have_content("John Smith")
  end

  step 'I should not see user "John Smith"' do
    expect(page).not_to have_content("John Smith")
  end

  step 'I should see user "Mary Jane"' do
    expect(page).to have_content("Mary Jane")
  end

  step 'I search for user "mary"' do
    fill_in 'users_search', :with => 'mary'
    click_button('Search')
  end
end

