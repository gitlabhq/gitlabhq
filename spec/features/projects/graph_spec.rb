# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Graph', :js, feature_category: :source_code_management do
  let(:user) { create(:user) }
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
      expect(page).to have_button(branch_name)
    end
  end

  context 'charts graph ref switcher' do
    it 'switches ref to branch' do
      ref_name = 'add-pdf-file'
      visit charts_project_graph_path(project, 'master')

      # Not a huge fan of using a HTML (CSS) selectors here as any change of them will cause a failed test
      ref_selector = find('.ref-selector .gl-new-dropdown-toggle')
      scroll_to(ref_selector)
      ref_selector.click

      page.within '.gl-new-dropdown-contents' do
        dropdown_branch_item = find('li', text: 'add-pdf-file')
        scroll_to(dropdown_branch_item)
        dropdown_branch_item.click
      end

      scroll_to(find('.tree-ref-header'), align: :center)
      expect(page).to have_selector '.gl-new-dropdown-toggle', text: ref_name
      page.within '.tree-ref-header' do
        expect(page).to have_selector('h4', text: ref_name)
      end
    end
  end

  context 'when CI enabled' do
    subject(:visit_path) { visit ci_project_graph_path(project, 'master') }

    before do
      project.enable_ci
    end

    context 'with ci_improved_project_pipeline_analytics feature flag on' do
      it 'renders Pipeline graphs' do
        visit_path

        expect(page).to have_content 'CI/CD Analytics'
        expect(page).to have_content 'Pipelines'
      end
    end

    context 'with ci_improved_project_pipeline_analytics feature flag off' do
      before do
        stub_feature_flags(ci_improved_project_pipeline_analytics: false)
      end

      it 'renders CI graphs' do
        visit_path

        expect(page).to have_content 'CI/CD Analytics'
        expect(page).to have_content 'Last week'
        expect(page).to have_content 'Last month'
        expect(page).to have_content 'Last year'
        expect(page).to have_content 'Pipeline durations for the last 30 commits'
      end
    end
  end
end
