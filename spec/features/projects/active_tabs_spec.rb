# frozen_string_literal: true

require 'spec_helper'

describe 'Project active tab' do
  let(:user) { create :user }
  let(:project) { create(:project, :repository) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  def click_tab(title)
    page.within '.sidebar-top-level-items > .active' do
      click_link(title)
    end
  end

  context 'on project Home' do
    before do
      visit project_path(project)
    end

    it_behaves_like 'page has active tab', 'Project'
    it_behaves_like 'page has active sub tab', 'Details'

    context 'on project Home/Activity' do
      before do
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
    before do
      visit project_issues_path(project)
    end

    it_behaves_like 'page has active tab', 'Issues'

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

  context 'on project Merge Requests' do
    before do
      visit project_merge_requests_path(project)
    end

    it_behaves_like 'page has active tab', 'Merge Requests'
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
      visit charts_project_graph_path(project, 'master')
    end

    context 'on project Analytics/Repository Analytics' do
      it_behaves_like 'page has active tab', _('Analytics')
      it_behaves_like 'page has active sub tab', _('Repository')
    end

    context 'on project Analytics/Cycle Analytics' do
      before do
        click_tab(_('CI / CD'))
      end

      it_behaves_like 'page has active tab', _('Analytics')
      it_behaves_like 'page has active sub tab', _('CI / CD')
    end
  end
end
