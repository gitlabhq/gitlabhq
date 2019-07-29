# frozen_string_literal: true

require 'spec_helper'

describe 'Project Graph', :js do
  let(:user) { create :user }
  let(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:branch_name) { 'master' }

  before do
    ::Projects::DetectRepositoryLanguagesService.new(project, user).execute

    project.add_maintainer(user)

    sign_in(user)
  end

  shared_examples 'page should have commits graphs' do
    it 'renders commits' do
      expect(page).to have_content("Commit statistics for #{branch_name}")
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

  context 'chart graph with HTML escaped branch name' do
    let(:branch_name) { '<h1>evil</h1>' }

    before do
      project.repository.create_branch(branch_name, 'master')

      visit charts_project_graph_path(project, branch_name)
    end

    it_behaves_like 'page should have commits graphs'

    it 'HTML escapes branch name' do
      expect(page.body).to include("Commit statistics for <strong>#{ERB::Util.html_escape(branch_name)}</strong>")
      expect(page.body).not_to include(branch_name)
    end
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
