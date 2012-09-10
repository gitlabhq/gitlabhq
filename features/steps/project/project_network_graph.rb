class ProjectNetworkGraph < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject

  Then 'page should have network graph' do
    page.should have_content "Project Network Graph"
    within ".graph" do
      page.should have_content "master"
      page.should have_content "scss_refactor..."
    end
  end

  And 'I visit project "Shop" network page' do
    project = Project.find_by_name("Shop")

    # Stub out find_all to speed this up (10 commits vs. 650)
    commits = Grit::Commit.find_all(project.repo, nil, {max_count: 10})
    Grit::Commit.stub(:find_all).and_return(commits)

    visit graph_project_path(project)
  end
end
