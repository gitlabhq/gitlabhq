class Spinach::Features::ProjectGraph < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject

  step 'page should have graphs' do
    expect(page).to have_selector ".stat-graph"
  end

  When 'I visit project "Shop" graph page' do
    visit namespace_project_graph_path(project.namespace, project, "master")
  end

  step 'I visit project "Shop" commits graph page' do
    visit commits_namespace_project_graph_path(project.namespace, project, "master")
  end

  step 'I visit project "Shop" languages graph page' do
    visit languages_namespace_project_graph_path(project.namespace, project, "master")
  end

  step 'page should have languages graphs' do
    expect(page).to have_content "Ruby 66.63 %"
    expect(page).to have_content "JavaScript 22.96 %"
  end

  step 'page should have commits graphs' do
    expect(page).to have_content "Commit statistics for master"
    expect(page).to have_content "Commits per day of month"
  end

  step 'I visit project "Shop" CI graph page' do
    visit ci_namespace_project_graph_path(project.namespace, project, 'master')
  end

  step 'page should have CI graphs' do
    expect(page).to have_content 'Overall'
    expect(page).to have_content 'Builds for last week'
    expect(page).to have_content 'Builds for last month'
    expect(page).to have_content 'Builds for last year'
    expect(page).to have_content 'Commit duration in minutes for last 30 commits'
  end

  def project
    @project ||= Project.find_by(name: "Shop")
  end
end
