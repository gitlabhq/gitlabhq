class Spinach::Features::PublicUsers < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedUser

  step 'I should not see user "John Van Public"' do
    expect(page).not_to have_content("John Van Public")
  end

  step 'I should see user "John Van Public"' do
    expect(page).to have_content("John Van Public")
  end

  step 'I should see user "John Van Internal"' do
    expect(page).to have_content("John Van Internal")
  end

  step 'I should not see user "John Van Internal"' do
    expect(page).not_to have_content("John John Van Internal")
  end

  step 'I should not see user "John Van Private"' do
    expect(page).not_to have_content("John Van Private")
  end

  step 'I search for user "inter"' do
    fill_in 'users_search', :with => 'inter'
    click_button('Search')
  end
end
