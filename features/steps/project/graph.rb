class Spinach::Features::ProjectGraph < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject

  step 'page should have graphs' do
    expect(page).to have_selector ".stat-graph"
  end

  When 'I visit project "Shop" graph page' do
    project = Project.find_by(name: "Shop")
    visit namespace_project_graph_path(project.namespace, project, "master")
  end

  step 'I visit project "Shop" commits graph page' do
    project = Project.find_by(name: "Shop")
    visit commits_namespace_project_graph_path(project.namespace, project, "master")
  end

  step 'page should have commits graphs' do
    expect(page).to have_content "Commit statistics for master"
    expect(page).to have_content "Commits per day of month"
  end
end
