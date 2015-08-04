class Spinach::Features::ProjectNetworkGraph < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'page should have network graph' do
    expect(page).to have_selector ".network-graph"
  end

  When 'I visit project "Shop" network page' do
    # Stub Graph max_size to speed up test (10 commits vs. 650)
    Network::Graph.stub(max_count: 10)

    @project = Project.find_by(name: "Shop")
    visit namespace_project_network_path(@project.namespace, @project, "master")
  end

  step "I visit project network page on branch 'test'" do
    visit namespace_project_network_path(@project.namespace, @project, "'test'")
  end

  step 'page should select "master" in select box' do
    expect(page).to have_selector '.select2-chosen', text: "master"
  end

  step 'page should select "v1.0.0" in select box' do
    expect(page).to have_selector '.select2-chosen', text: "v1.0.0"
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
    select 'feature', from: 'ref'
    sleep 2
  end

  When 'I switch ref to "v1.0.0"' do
    select 'v1.0.0', from: 'ref'
    sleep 2
  end

  When 'click "Show only selected branch" checkbox' do
    find('#filter_ref').click
    sleep 2
  end

  step 'page should have content not containing "v1.0.0"' do
    page.within '.network-graph' do
      expect(page).to have_content 'Change some files'
    end
  end

  step 'page should not have content not containing "v1.0.0"' do
    page.within '.network-graph' do
      expect(page).not_to have_content 'Change some files'
    end
  end

  step 'page should select "feature" in select box' do
    expect(page).to have_selector '.select2-chosen', text: "feature"
  end

  step 'page should select "v1.0.0" in select box' do
    expect(page).to have_selector '.select2-chosen', text: "v1.0.0"
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
