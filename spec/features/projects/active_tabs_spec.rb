# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project active tab' do
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.owner }

  before do
    sign_in(user)
  end

  def click_tab(title)
    page.within '.sidebar-top-level-items > .active' do
      click_link(title)
    end
  end

  context 'on project Home' do
    it 'activates Project scope menu' do
      visit project_path(project)

      expect(page).to have_selector('.sidebar-top-level-items > li.active', count: 1)
      expect(find('.sidebar-top-level-items > li.active')).to have_content(project.name)
    end
  end

  context 'on Project information' do
    context 'default link' do
      before do
        visit project_path(project)

        click_link('Project information', match: :first)
      end

      it_behaves_like 'page has active tab', 'Project'
      it_behaves_like 'page has active sub tab', 'Activity'
    end

    context 'on Project information/Activity' do
      before do
        visit activity_project_path(project)
      end

      it_behaves_like 'page has active tab', 'Project'
      it_behaves_like 'page has active sub tab', 'Activity'
    end
  end

  context 'on project Repository' do
    before do
      root_ref = project.repository.root_ref
      visit project_tree_path(project, root_ref)
    end

    it_behaves_like 'page has active tab', 'Repository'

    %w(Files Commits Graph Compare Branches Tags).each do |sub_menu|
      context "on project Repository/#{sub_menu}" do
        before do
          click_tab(sub_menu)
        end

        it_behaves_like 'page has active tab', 'Repository'
        it_behaves_like 'page has active sub tab', sub_menu
      end
    end
  end

  context 'on project Issues' do
    before do
      visit project_issues_path(project)
    end

    it_behaves_like 'page has active tab', 'Issues'

    context "on project Issues/Milestones" do
      before do
        click_tab('Milestones')
      end

      it_behaves_like 'page has active tab', 'Issues'
      it_behaves_like 'page has active sub tab', 'Milestones'
    end
  end

  context 'on project Merge Requests' do
    before do
      visit project_merge_requests_path(project)
    end

    it_behaves_like 'page has active tab', 'Merge requests'
  end

  context 'on project Wiki' do
    before do
      visit wiki_path(project.wiki)
    end

    it_behaves_like 'page has active tab', 'Wiki'
  end

  context 'on project Members' do
    before do
      visit project_project_members_path(project)
    end

    it_behaves_like 'page has active tab', 'Members'
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

  context 'on project Analytics' do
    before do
      visit project_cycle_analytics_path(project)
    end

    context 'on project Analytics/Value stream Analytics' do
      it_behaves_like 'page has active tab', _('Analytics')
      it_behaves_like 'page has active sub tab', _('Value stream')
    end

    context 'on project Analytics/"CI/CD"' do
      before do
        click_tab(_('CI/CD'))
      end

      it_behaves_like 'page has active tab', _('Analytics')
      it_behaves_like 'page has active sub tab', _('CI/CD')
    end
  end

  context 'on project CI/CD' do
    context 'browsing Pipelines tabs' do
      let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

      context 'Pipeline tab' do
        before do
          visit project_pipeline_path(project, pipeline)
        end

        it_behaves_like 'page has active tab', _('CI/CD')
        it_behaves_like 'page has active sub tab', _('Pipelines')
      end

      context 'Needs tab' do
        before do
          visit dag_project_pipeline_path(project, pipeline)
        end

        it_behaves_like 'page has active tab', _('CI/CD')
        it_behaves_like 'page has active sub tab', _('Pipelines')
      end

      context 'Builds tab' do
        before do
          visit builds_project_pipeline_path(project, pipeline)
        end

        it_behaves_like 'page has active tab', _('CI/CD')
        it_behaves_like 'page has active sub tab', _('Pipelines')
      end

      context 'Failures tab' do
        before do
          visit failures_project_pipeline_path(project, pipeline)
        end

        it_behaves_like 'page has active tab', _('CI/CD')
        it_behaves_like 'page has active sub tab', _('Pipelines')
      end

      context 'Test Report tab' do
        before do
          visit test_report_project_pipeline_path(project, pipeline)
        end

        it_behaves_like 'page has active tab', _('CI/CD')
        it_behaves_like 'page has active sub tab', _('Pipelines')
      end
    end
  end
end
