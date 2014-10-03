class Spinach::Features::Search < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I search for "Sho"' do
    fill_in "dashboard_search", with: "Sho"
    click_button "Search"
  end

  step 'I search for "Foo"' do
    fill_in "dashboard_search", with: "Foo"
    click_button "Search"
  end

  step 'I search for "rspec"' do
    fill_in "dashboard_search", with: "rspec"
    click_button "Search"
  end

  step 'I click "Issues" link' do
    within '.search-filter' do
      click_link 'Issues'
    end
  end

  step 'I click project "Shop" link' do
    within '.project-filter' do
      click_link project.name_with_namespace
    end
  end

  step 'I click "Merge requests" link' do
    within '.search-filter' do
      click_link 'Merge requests'
    end
  end

  step 'I should see "Shop" project link' do
    page.should have_link "Shop"
  end

  step 'I should see code results for project "Shop"' do
    page.should have_content 'Update capybara, rspec-rails, poltergeist to recent versions'
  end

  step 'I search for "Contibuting"' do
    fill_in "dashboard_search", with: "Contibuting"
    click_button "Search"
  end

  step 'project has issues' do
    create(:issue, title: "Foo", project: project)
    create(:issue, title: "Bar", project: project)
  end

  step 'project has merge requests' do
    create(:merge_request, title: "Foo", source_project: project, target_project: project)
    create(:merge_request, :simple, title: "Bar", source_project: project, target_project: project)
  end

  step 'I should see "Foo" link' do
    page.should have_link "Foo"
  end

  step 'I should not see "Bar" link' do
    page.should_not have_link "Bar"
  end
end
