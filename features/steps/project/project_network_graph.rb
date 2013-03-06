class ProjectNetworkGraph < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject

  Then 'page should have network graph' do
    page.should have_content "Project Network Graph"
    page.should have_selector ".graph"
  end

  When 'I visit project "Shop" network page' do
    # Stub Graph::JsonBuilder max_size to speed up test (10 commits vs. 650)
    Graph::JsonBuilder.stub(max_count: 10)

    project = Project.find_by_name("Shop")
    visit project_graph_path(project, "master")
  end

  And 'page should select "master" in select box' do
    page.should have_selector '#ref_chzn span', :text => "master"
  end

  And 'page should have "master" on graph' do
    within '.graph' do
      page.should have_content 'master'
    end
  end

  And 'I switch ref to "stable"' do
    page.select 'stable', :from => 'ref'
    sleep 2
  end

  And 'page should select "stable" in select box' do
    page.should have_selector '#ref_chzn span', :text => "stable"
  end

  And 'page should have "stable" on graph' do
    within '.graph' do
      page.should have_content 'stable'
    end
  end

  And 'I looking for a commit by SHA of "v2.1.0"' do
    within ".content .search" do
      fill_in 'q', :with => '98d6492'
      find('button').click
    end
    sleep 2
  end

  And 'page should have "v2.1.0" on graph' do
    within '.graph' do
      page.should have_content 'v2.1.0'
    end
  end
end
