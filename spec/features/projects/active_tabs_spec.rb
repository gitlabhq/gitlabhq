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
    context 'when feature flag :sidebar_refactor is enabled' do
      before do
        visit project_path(project)
      end

      it_behaves_like 'page has active tab', 'Project'
    end

    context 'when feature flag :sidebar_refactor is disabled' do
      before do
        stub_feature_flags(sidebar_refactor: false)

        visit project_path(project)
      end

      it_behaves_like 'page has active tab', 'Project'
      it_behaves_like 'page has active sub tab', 'Details'
    end

    context 'on project Home/Activity' do
      before do
        visit project_path(project)
        click_tab('Activity')
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
    let(:feature_flag_value) { true }

    before do
      stub_feature_flags(sidebar_refactor: feature_flag_value)

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

    context 'when feature flag is disabled' do
      let(:feature_flag_value) { false }

      %w(Milestones Labels).each do |sub_menu|
        context "on project Issues/#{sub_menu}" do
          before do
            click_tab(sub_menu)
          end

          it_behaves_like 'page has active tab', 'Issues'
          it_behaves_like 'page has active sub tab', sub_menu
        end
      end
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

    context 'on project Analytics/Value Stream Analytics' do
      it_behaves_like 'page has active tab', _('Analytics')
      it_behaves_like 'page has active sub tab', _('Value Stream')
    end

    context 'on project Analytics/"CI/CD"' do
      before do
        click_tab(_('CI/CD'))
      end

      it_behaves_like 'page has active tab', _('Analytics')
      it_behaves_like 'page has active sub tab', _('CI/CD')
    end
  end
end
