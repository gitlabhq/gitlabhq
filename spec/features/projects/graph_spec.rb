require 'spec_helper'

describe 'Project Graph', :js do
  let(:user) { create :user }
  let(:project) { create(:project, :repository, namespace: user.namespace) }

  before do
    project.add_master(user)

    sign_in(user)
  end

  shared_examples 'page should have commits graphs' do
    it 'renders commits' do
      expect(page).to have_content('Commit statistics for master')
      expect(page).to have_content('Commits per day of month')
    end
  end

  shared_examples 'page should have languages graphs' do
    it 'renders languages' do
      expect(page).to have_content(/Ruby 66.* %/)
      expect(page).to have_content(/JavaScript 22.* %/)
    end
  end

  it 'renders graphs' do
    visit project_graph_path(project, 'master')

    expect(page).to have_selector('.stat-graph', visible: false)
  end

  context 'commits graph' do
    before do
      visit commits_project_graph_path(project, 'master')
    end

    it_behaves_like 'page should have commits graphs'
    it_behaves_like 'page should have languages graphs'
  end

  context 'languages graph' do
    before do
      visit languages_project_graph_path(project, 'master')
    end

    it_behaves_like 'page should have commits graphs'
    it_behaves_like 'page should have languages graphs'
  end

  context 'charts graph' do
    before do
      visit charts_project_graph_path(project, 'master')
    end

    it_behaves_like 'page should have commits graphs'
    it_behaves_like 'page should have languages graphs'
  end

  context 'when CI enabled' do
    before do
      project.enable_ci

      visit ci_project_graph_path(project, 'master')
    end

    it 'renders CI graphs' do
      expect(page).to have_content 'Overall'
      expect(page).to have_content 'Pipelines for last week'
      expect(page).to have_content 'Pipelines for last month'
      expect(page).to have_content 'Pipelines for last year'
      expect(page).to have_content 'Commit duration in minutes for last 30 commits'
    end
  end
end
