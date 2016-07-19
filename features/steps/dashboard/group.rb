class Spinach::Features::DashboardGroup < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedGroup
  include SharedPaths
  include SharedUser

  step 'I click new group link' do
    click_link "New Group"
  end

  step 'submit form with new group "Samurai" info' do
    fill_in 'group_path', with: 'Samurai'
    fill_in 'group_description', with: 'Tokugawa Shogunate'
    click_button "Create group"
  end

  step 'I should be redirected to group "Samurai" page' do
    expect(current_path).to eq group_path(Group.find_by(name: 'Samurai'))
  end

  step 'I should see newly created group "Samurai"' do
    expect(page).to have_content "Samurai"
    expect(page).to have_content "Tokugawa Shogunate"
  end
end
