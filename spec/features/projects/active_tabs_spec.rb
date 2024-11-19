# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project active tab', :js, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :with_namespace_settings, namespace: user.namespace) }

  before do
    sign_in(user)
  end

  def click_tab(title)
    within_testid('super-sidebar') do
      click_link(title)
    end
  end

  context 'on project Home' do
    it 'activates Project scope menu' do
      visit project_path(project)

      within_testid('super-sidebar') do
        expect(page).to have_selector('a[aria-current="page"]', count: 1)
        expect(find('a[aria-current="page"]')).to have_content(project.name)
      end
    end
  end

  context 'on Project Manage' do
    %w[Activity Members Labels].each do |sub_menu|
      context "on project Manage/#{sub_menu}" do
        before do
          visit project_path(project)
          within_testid('super-sidebar') do
            click_button("Manage")
          end
          click_tab(sub_menu)
        end

        it_behaves_like 'page has active tab', 'Manage'
        it_behaves_like 'page has active sub tab', sub_menu
      end
    end
  end

  context 'on project Code' do
    before do
      root_ref = project.repository.root_ref
      visit project_tree_path(project, root_ref)

      # Enabling Js in here causes more SQL queries to be caught by the query limiter.
      # We are increasing the limit here so that the tests pass.
      allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(110)
    end

    it_behaves_like 'page has active tab', 'Code'

    ["Repository", "Branches", "Commits", "Tags", "Repository graph", "Compare revisions"].each do |sub_menu|
      context "on project Code/#{sub_menu}" do
        before do
          click_tab(sub_menu)
        end

        it_behaves_like 'page has active tab', 'Code'
        it_behaves_like 'page has active sub tab', sub_menu
      end
    end
  end

  context 'on project Plan' do
    before do
      visit project_issues_path(project)
    end

    it_behaves_like 'page has active tab', 'Plan'

    context 'on project Plan/Milestones' do
      before do
        click_tab('Milestones')
      end

      it_behaves_like 'page has active tab', 'Plan'
      it_behaves_like 'page has active sub tab', 'Milestones'
    end
  end

  context 'on project Merge Requests' do
    before do
      visit project_merge_requests_path(project)
    end

    it_behaves_like 'page has active tab', 'Pinned'
  end

  context 'on project Wiki' do
    before do
      visit wiki_path(project.wiki)
    end

    it_behaves_like 'page has active tab', 'Plan'
    it_behaves_like 'page has active sub tab', 'Wiki'
  end

  context 'on project Members' do
    before do
      visit project_project_members_path(project)
    end

    it_behaves_like 'page has active tab', 'Manage'
    it_behaves_like 'page has active sub tab', 'Members'
  end

  context 'on project Settings' do
    before do
      visit edit_project_path(project)
    end

    context 'on project Settings/Integrations' do
      before do
        click_tab('Integrations')
      end

      it_behaves_like 'page has active tab', 'Settings'
      it_behaves_like 'page has active sub tab', 'Integrations'
    end

    context 'on project Settings/Repository' do
      before do
        click_tab('Repository')
      end

      it_behaves_like 'page has active tab', 'Settings'
      it_behaves_like 'page has active sub tab', 'Repository'
    end
  end

  context 'on project Analyze' do
    before do
      visit project_cycle_analytics_path(project)
    end

    context 'on project Analyze/Value stream Analyze' do
      it_behaves_like 'page has active tab', _('Analyze')
      it_behaves_like 'page has active sub tab', _('Value stream')
    end

    context 'on project Analyze/"CI/CD"' do
      before do
        click_tab(_('CI/CD'))
      end

      it_behaves_like 'page has active tab', _('Analyze')
      it_behaves_like 'page has active sub tab', _('CI/CD analytics')
    end
  end

  context 'on project CI/CD' do
    context 'browsing Pipelines tabs' do
      let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

      context 'Pipeline tab' do
        before do
          visit project_pipeline_path(project, pipeline)
        end

        it_behaves_like 'page has active tab', _('Build')
        it_behaves_like 'page has active sub tab', _('Pipelines')
      end

      context 'Builds tab' do
        before do
          visit builds_project_pipeline_path(project, pipeline)
        end

        it_behaves_like 'page has active tab', _('Build')
        it_behaves_like 'page has active sub tab', _('Pipelines')
      end

      context 'Failures tab' do
        before do
          visit failures_project_pipeline_path(project, pipeline)
        end

        it_behaves_like 'page has active tab', _('Build')
        it_behaves_like 'page has active sub tab', _('Pipelines')
      end

      context 'Test Report tab' do
        before do
          visit test_report_project_pipeline_path(project, pipeline)
        end

        it_behaves_like 'page has active tab', _('Build')
        it_behaves_like 'page has active sub tab', _('Pipelines')
      end
    end
  end
end
