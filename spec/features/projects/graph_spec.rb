# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Graph', :js do
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

  context 'commits graph' do
    before do
      visit commits_project_graph_path(project, 'master')
    end

    it_behaves_like 'page should have commits graphs'
  end

  context 'languages graph' do
    before do
      visit languages_project_graph_path(project, 'master')
    end

    it_behaves_like 'page should have commits graphs'
  end

  context 'charts graph' do
    before do
      visit charts_project_graph_path(project, 'master')
    end

    it_behaves_like 'page should have commits graphs'
  end

  context 'chart graph with HTML escaped branch name' do
    let(:branch_name) { '<h1>evil</h1>' }

    before do
      project.repository.create_branch(branch_name)

      visit charts_project_graph_path(project, branch_name)
    end

    it_behaves_like 'page should have commits graphs'

    it 'HTML escapes branch name' do
      expect(page.body).to include("Commit statistics for <strong>#{ERB::Util.html_escape(branch_name)}</strong>")
      expect(page.find('.dropdown-toggle-text')['innerHTML']).to eq(ERB::Util.html_escape(branch_name))
    end
  end

  context 'when CI enabled' do
    before do
      project.enable_ci

      visit ci_project_graph_path(project, 'master')
    end

    it 'renders CI graphs' do
      expect(page).to have_content 'Overall'
      expect(page).to have_content 'Last week'
      expect(page).to have_content 'Last month'
      expect(page).to have_content 'Last year'
      expect(page).to have_content 'Pipeline durations for the last 30 commits'
    end
  end
end
