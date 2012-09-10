class ProjectNetworkGraph < Spinach::FeatureSteps
  Then 'page should have network graph' do
    page.should have_content "Project Network Graph"
    within ".graph" do
      page.should have_content "master"
      page.should have_content "scss_refactor..."
    end
  end

  Given 'I sign in as a user' do
    login_as :user
  end

  And 'I own project "Shop"' do
    @project = Factory :project, :name => "Shop"
    @project.add_access(@user, :admin)
  end

  And 'I visit project "Shop" network page' do
    project = Project.find_by_name("Shop")

    # Stub out find_all to speed this up (10 commits vs. 650)
    commits = Grit::Commit.find_all(project.repo, nil, {max_count: 10})
    Grit::Commit.stub(:find_all).and_return(commits)

    visit graph_project_path(project)
  end
end
