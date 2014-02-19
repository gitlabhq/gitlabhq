class ProfileGroup < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedGroup
  include SharedPaths
  include SharedUser

  # Leave

  step 'I click on the "Leave" button for group "Owned"' do
    find(:css, 'li', text: "Owner").find(:css, 'i.icon-signout').click
    # poltergeist always confirms popups.
  end

  step 'I click on the "Leave" button for group "Guest"' do
    find(:css, 'li', text: "Guest").find(:css, 'i.icon-signout').click
    # poltergeist always confirms popups.
  end

  step 'I should not see the "Leave" button for group "Owned"' do
    find(:css, 'li', text: "Owner").should_not have_selector(:css, 'i.icon-signout')
    # poltergeist always confirms popups.
  end

  step 'I should not see the "Leave" button for groupr "Guest"' do
    find(:css, 'li', text: "Guest").should_not have_selector(:css,  'i.icon-signout')
    # poltergeist always confirms popups.
  end

  step 'I should see group "Owned" in group list' do
    page.should have_content("Owned")
  end

  step 'I should not see group "Owned" in group list' do
    page.should_not have_content("Owned")
  end

  step 'I should see group "Guest" in group list' do
    page.should have_content("Guest")
  end

  step 'I should not see group "Guest" in group list' do
    page.should_not have_content("Guest")
  end
end
