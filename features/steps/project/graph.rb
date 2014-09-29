class Spinach::Features::ProjectGraph < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject

  step 'page should have graphs' do
    page.should have_selector ".stat-graph"
  end

  When 'I visit project "Shop" graph page' do
    project = Project.find_by(name: "Shop")
    visit project_graph_path(project, "master")
  end

  step 'I visit project "Shop" commits graph page' do
    project = Project.find_by(name: "Shop")
    visit commits_project_graph_path(project, "master")
  end

  step 'page should have commits graphs' do
    page.should have_content "Commits statistic for master"
    page.should have_content "Commits per day of month"
  end
end
