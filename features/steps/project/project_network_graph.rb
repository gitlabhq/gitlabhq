class ProjectNetworkGraph < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject

  Then 'page should have network graph' do
    page.should have_content "Project Network Graph"
    within ".graph" do
      page.should have_content "master"
    end
  end

  And 'I visit project "Shop" network page' do
    # Stub Graph::JsonBuilder max_size to speed up test (10 commits vs. 650)
    Gitlab::Graph::JsonBuilder.stub(max_count: 10)

    project = Project.find_by_name("Shop")
    visit project_graph_path(project, "master")
  end
end
