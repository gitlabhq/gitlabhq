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

  step 'I search for "Wiki content"' do
    fill_in "dashboard_search", with: "content"
    click_button "Search"
  end

  step 'I click "Issues" link' do
    page.within '.search-filter' do
      click_link 'Issues'
    end
  end

  step 'I click project "Shop" link' do
    page.within '.project-filter' do
      click_link project.name_with_namespace
    end
  end

  step 'I click "Merge requests" link' do
    page.within '.search-filter' do
      click_link 'Merge requests'
    end
  end

  step 'I click "Milestones" link' do
    page.within '.search-filter' do
      click_link 'Milestones'
    end
  end

  step 'I click "Wiki" link' do
    page.within '.search-filter' do
      click_link 'Wiki'
    end
  end

  step 'I should see "Shop" project link' do
    expect(page).to have_link "Shop"
  end

  step 'I should see code results for project "Shop"' do
    page.within('.results') do
      page.should have_content 'Update capybara, rspec-rails, poltergeist to recent versions'
    end
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

  step 'project has milestones' do
    create(:milestone, title: "Foo", project: project)
    create(:milestone, title: "Bar", project: project)
  end

  step 'I should see "Foo" link in the search results' do
    page.within('.results') do
      find(:css, '.search-results').should have_link 'Foo'
    end
  end

  step 'I should not see "Bar" link in the search results' do
    expect(find(:css, '.search-results')).not_to have_link 'Bar'
  end

  step 'I should see "test_wiki" link in the search results' do
    page.within('.results') do
      find(:css, '.search-results').should have_link 'test_wiki.md'
    end
  end

  step 'project has Wiki content' do
    @wiki = ::ProjectWiki.new(project, current_user)
    @wiki.create_page("test_wiki", "Some Wiki content", :markdown, "first commit")
  end
end
