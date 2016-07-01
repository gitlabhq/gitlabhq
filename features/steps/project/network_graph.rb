class Spinach::Features::ProjectNetworkGraph < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'page should have network graph' do
    expect(page).to have_selector ".network-graph"
  end

  When 'I visit project "Shop" network page' do
    # Stub Graph max_size to speed up test (10 commits vs. 650)
    allow(Network::Graph).to receive(:max_count).and_return(10)

    @project = Project.find_by(name: "Shop")
    visit namespace_project_network_path(@project.namespace, @project, "master")
  end

  step "I visit project network page on branch 'test'" do
    visit namespace_project_network_path(@project.namespace, @project, "'test'")
  end

  step 'page should select "master" in select box' do
    expect(page).to have_selector '.dropdown-menu-toggle', text: "master"
  end

  step 'page should select "v1.0.0" in select box' do
    expect(page).to have_selector '.dropdown-menu-toggle', text: "v1.0.0"
  end

  step 'page should have "master" on graph' do
    page.within '.network-graph' do
      expect(page).to have_content 'master'
    end
  end

  step "page should have 'test' on graph" do
    page.within '.network-graph' do
      expect(page).to have_content "'test'"
    end
  end

  When 'I switch ref to "feature"' do
    first('.js-project-refs-dropdown').click

    page.within '.project-refs-form' do
      click_link 'feature'
    end
  end

  When 'I switch ref to "v1.0.0"' do
    first('.js-project-refs-dropdown').click

    page.within '.project-refs-form' do
      click_link 'v1.0.0'
    end
  end

  When 'click "Show only selected branch" checkbox' do
    find('#filter_ref').click
  end

  step 'page should have content not containing "v1.0.0"' do
    page.within '.network-graph' do
      expect(page).to have_content 'Change some files'
    end
  end

  step 'page should have "v1.0.0" in title' do
    expect(page).to have_css 'title', text: 'Network · v1.0.0', visible: false
  end

  step 'page should only have content from "v1.0.0"' do
    page.within '.network-graph' do
      expect(page).not_to have_content 'Change some files'
    end
  end

  step 'page should select "feature" in select box' do
    expect(page).to have_selector '.dropdown-menu-toggle', text: "feature"
  end

  step 'page should select "v1.0.0" in select box' do
    expect(page).to have_selector '.dropdown-menu-toggle', text: "v1.0.0"
  end

  step 'page should have "feature" on graph' do
    page.within '.network-graph' do
      expect(page).to have_content 'feature'
    end
  end

  When 'I looking for a commit by SHA of "v1.0.0"' do
    page.within ".network-form" do
      fill_in 'extended_sha1', with: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9'
      find('button').click
    end
    sleep 2
  end

  step 'page should have "v1.0.0" on graph' do
    page.within '.network-graph' do
      expect(page).to have_content 'v1.0.0'
    end
  end

  When 'I look for a commit by ";"' do
    page.within ".network-form" do
      fill_in 'extended_sha1', with: ';'
      find('button').click
    end
  end
end
