# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard Issues', :js, :with_current_organization, feature_category: :team_planning do
  include FilteredSearchHelpers

  let_it_be(:current_user) { create(:user, organization: current_organization) }
  let_it_be(:user) { current_user } # Shared examples depend on this being available
  let_it_be(:public_project) { create(:project, :public) }
  let_it_be(:project) { create(:project) }
  let_it_be(:project_with_issues_disabled) { create(:project, :issues_disabled) }
  let_it_be(:authored_issue) { create :issue, author: current_user, project: project }
  let_it_be(:authored_issue_on_public_project) { create :issue, author: current_user, project: public_project }
  let_it_be(:assigned_issue) { create :issue, assignees: [current_user], project: project }
  let_it_be(:other_issue) { create :issue, project: project }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
    [project, project_with_issues_disabled].each { |project| project.add_maintainer(current_user) }
    sign_in(current_user)
  end

  def visit_dashboard_issues
    visit issues_dashboard_path(assignee_username: current_user.username)
  end

  it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :issues_dashboard_path, :issues

  it_behaves_like 'page with product usage data collection banner' do
    let(:page_path) { issues_dashboard_path(assignee_username: user.username) }
  end

  context 'for accessibility testing' do
    before do
      visit_dashboard_issues
    end

    let_it_be(:detailed_assigned_issue) do
      create :issue,
        :closed,
        :locked,
        assignees: [current_user],
        project: project
    end

    it 'passes axe automated accessibility testing',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/468892' do
      expect(page).to be_axe_clean.within('#content-body')
    end
  end

  describe 'issues' do
    before do
      visit_dashboard_issues
    end

    it 'shows issues assigned to current user' do
      expect(page).to have_content(assigned_issue.title)
      expect(page).not_to have_content(authored_issue.title)
      expect(page).not_to have_content(other_issue.title)
    end

    it 'shows issues when current user is author' do
      click_button 'Clear'
      select_tokens 'Author', '=', current_user.to_reference, submit: true

      expect(page).to have_content(authored_issue.title)
      expect(page).to have_content(authored_issue_on_public_project.title)
      expect(page).not_to have_content(assigned_issue.title)
      expect(page).not_to have_content(other_issue.title)
    end

    it 'state filter tabs work' do
      click_link 'Closed'

      expect(page).not_to have_content(assigned_issue.title)
      expect(page).not_to have_content(authored_issue.title)
      expect(page).not_to have_content(other_issue.title)
    end

    describe 'RSS link' do
      before do
        click_button 'Actions'
      end

      it_behaves_like "it has an RSS link with current_user's feed token"
      it_behaves_like "an autodiscoverable RSS feed with current_user's feed token"
    end
  end

  describe 'new issue dropdown' do
    before do
      visit_dashboard_issues
    end

    it 'shows projects only with issues feature enabled' do
      click_button _('Select project to create issue')

      within_testid('new-resource-dropdown') do
        within('[role="menu"]') do
          expect(page).to have_content(project.full_name)
          expect(page).not_to have_content(project_with_issues_disabled.full_name)
        end
      end
    end

    it 'shows the new issue page' do
      click_button _('Select project to create issue')
      click_button project.full_name
      click_link format(_('New issue in %{project}'), project: project.name)

      expect(page).to have_current_path("/#{project.full_path}/-/issues/new")
    end
  end
end
