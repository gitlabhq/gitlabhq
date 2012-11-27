class AdminGroups < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedActiveTab

  When 'I click new group link' do
    click_link "New Group"
  end

  And 'submit form with new group info' do
    fill_in 'group_name', :with => 'gitlab'
    click_button "Create group"
  end

  Then 'I should see newly created group' do
    page.should have_content "Group: gitlab"
  end

  Then 'I should be redirected to group page' do
    current_path.should == admin_group_path(Group.last)
  end
end

