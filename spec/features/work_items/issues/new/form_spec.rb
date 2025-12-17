# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New/edit issue', :js, feature_category: :team_planning do
  include ActionView::Helpers::JavaScriptHelper
  include ListboxHelpers

  let_it_be(:project)   { create(:project, :repository) }
  let_it_be(:user)      { create(:user, maintainer_of: project) }
  let_it_be(:user2)     { create(:user, maintainer_of: project) }
  let_it_be(:guest)     { create(:user, guest_of: project) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:label)     { create(:label, project: project) }
  let_it_be(:label2)    { create(:label, project: project) }
  let_it_be(:issue)     { create(:issue, project: project, assignees: [user], milestone: milestone) }
  let_it_be(:confidential_issue) { create(:issue, project: project, assignees: [user], milestone: milestone, confidential: true) }

  let(:current_user) { user }

  before do
    stub_licensed_features(multiple_issue_assignees: false, issue_weights: false)
    stub_feature_flags(work_item_planning_view: false, okrs_mvc: false, service_desk_ticket: false)

    sign_in(current_user)
  end

  describe 'new issue' do
    describe 'single assignee' do
      before do
        visit new_project_issue_path(project)
      end

      it 'unselects other assignees when unassigned is selected' do
        within_testid('work-item-assignees') do
          click_button 'Edit'
          select_listbox_item(user2.name)

          click_button 'Edit'
          click_button 'Clear'

          expect(page).to have_text('None')
        end
      end

      it 'toggles assign to me when current user is selected and unselected' do
        within_testid('work-item-assignees') do
          expect(page).to have_button 'assign yourself'

          click_button 'Edit'
          select_listbox_item(user.name)

          expect(page).not_to have_button 'assign yourself'

          click_button 'Edit'
          click_button 'Clear'

          expect(page).to have_button 'assign yourself'
        end
      end
    end

    describe 'creating issue' do
      before do
        allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(110)
      end

      it 'allows user to create new issue' do
        visit new_project_issue_path(project)

        fill_in 'Title', with: 'title'
        fill_in 'Description', with: 'description'

        within_testid('work-item-assignees') do
          expect(page).to have_button 'assign yourself'

          click_button 'Edit'
          select_listbox_item(user2.name)

          expect(page).to have_link user2.name
          expect(page).not_to have_button 'assign yourself'

          click_button 'Edit'
          click_button 'Clear'

          expect(page).to have_button 'assign yourself'

          click_button 'assign yourself'

          expect(page).to have_link user.name
        end

        within_testid('work-item-milestone') do
          click_button 'Edit'
          select_listbox_item(milestone.title)

          expect(page).to have_link milestone.title
        end

        within_testid('work-item-labels') do
          click_button 'Edit'
          select_listbox_item(label.title)
          select_listbox_item(label2.title)
          send_keys(:escape)

          expect(page).to have_css('.gl-label', text: label.title)
          expect(page).to have_css('.gl-label', text: label2.title)
        end

        click_button 'Create issue'

        within_testid('work-item-overview-right-sidebar') do
          expect(page).to have_link user.name
          expect(page).to have_link milestone.title
          expect(page).to have_css('.gl-label', text: label.title)
          expect(page).to have_css('.gl-label', text: label2.title)
        end

        within_testid('breadcrumb-links') do
          issue = Issue.find_by(title: 'title')

          expect(page).to have_text("Issues #{issue.to_reference}")
        end
      end
    end

    it 'correctly updates the dropdown toggle when removing a label' do
      visit new_project_issue_path(project)

      within_testid('work-item-labels') do
        click_button 'Edit'
        select_listbox_item(label.title)
        send_keys(:escape)

        expect(page).to have_css('.gl-label', text: label.title)

        click_button 'Edit'
        select_first_listbox_item(label.title)
        send_keys(:escape)

        expect(page).not_to have_css('.gl-label', text: label.title)
      end
    end

    it 'clears label search input field when a label is selected', :js do
      visit new_project_issue_path(project)

      within_testid('work-item-labels') do
        click_button 'Edit'
        send_keys(label.title)

        within('.gl-listbox-search') do
          expect(page).to have_button 'Clear'
        end

        select_listbox_item(label.title)

        expect(page).to have_field('Search', with: '')
        within('.gl-listbox-search') do
          expect(page).not_to have_button 'Clear'
        end
      end
    end

    it 'displays an error message when submitting an invalid form' do
      visit new_project_issue_path(project)

      click_button 'Create issue'

      expect(page).to have_text('A title is required')
    end

    it 'correctly updates the selected user when changing assignee' do
      visit new_project_issue_path(project)

      within_testid('work-item-assignees') do
        click_button 'Edit'
        select_listbox_item(user.name)

        expect(page).to have_link(user.name)

        click_button 'Edit'
        select_listbox_item(user2.name)

        expect(page).to have_link(user2.name)
      end
    end

    it 'description has autocomplete' do
      visit new_project_issue_path(project)

      fill_in 'Description', with: '@'

      expect(page).to have_css('.atwho-view')
    end

    describe 'displays work item type options in the dropdown' do
      context 'when user is guest' do
        let_it_be(:guest) { create(:user) }

        let(:current_user) { guest }

        before_all do
          project.add_guest(guest)
        end

        it 'shows issues and tasks' do
          visit new_project_issue_path(project)

          # Update to omit Incident when https://gitlab.com/gitlab-org/gitlab/-/issues/543718 is complete
          expect(page).to have_select 'Type', options: %w[Incident Issue Task]
        end
      end

      context 'when user is reporter' do
        let_it_be(:reporter) { create(:user) }

        let(:current_user) { reporter }

        before_all do
          project.add_reporter(reporter)
        end

        it 'shows incidents, issues and tasks' do
          visit new_project_issue_path(project)

          expect(page).to have_select 'Type', options: %w[Incident Issue Task]
        end
      end
    end

    describe 'milestone' do
      let!(:milestone) do
        create(:milestone, title: '">&lt;img src=x onerror=alert(document.domain)&gt;', project: project)
      end

      it 'escapes milestone' do
        visit new_project_issue_path(project)

        within_testid('work-item-milestone') do
          click_button 'Edit'
          select_listbox_item(milestone.title)

          expect(page).to have_link milestone.title
          expect(page).not_to have_css 'img'
        end
      end
    end

    describe 'when repository contains CONTRIBUTING.md' do
      it 'has contribution guidelines prompt' do
        visit new_project_issue_path(project)

        expect(page).to have_text('Please review the contribution guidelines for this project.')
      end
    end
  end

  describe 'new issue with query parameters' do
    before do
      project.repository.create_file(
        current_user,
        '.gitlab/issue_templates/test_template.md',
        'description from template',
        message: 'Add test_template.md',
        branch_name: project.default_branch_or_main
      )
    end

    after do
      project.repository.delete_file(
        current_user,
        '.gitlab/issue_templates/test_template.md',
        message: 'Remove test_template.md',
        branch_name: project.default_branch_or_main
      )
    end

    it 'leaves the description blank if no query parameters are specified' do
      visit new_project_issue_path(project)

      expect(page).to have_field('Description', with: '')
    end

    it 'fills the description from the issue[description] query parameter' do
      visit new_project_issue_path(project, issue: { description: 'description from query parameter' })

      expect(page).to have_field('Description', with: 'description from query parameter')
    end

    it 'fills the description from the issuable_template query parameter' do
      visit new_project_issue_path(project, issuable_template: 'test_template')

      expect(page).to have_field('Description', with: 'description from template')
    end

    it 'fills the description from the issue[description] query parameter and shows an alert to replace the description with the template from issuable_template' do
      visit new_project_issue_path(project, issuable_template: 'test_template', issue: { description: 'description from query parameter' })

      expect(page).to have_field('Description', with: 'description from query parameter')
      expect(page).to have_text('Applying a template will replace the existing description. Any changes you have made will be lost.')
      expect(page).to have_button('Apply template')
    end
  end

  describe 'new issue from related issue' do
    it 'does not offer to link the new issue to any other issues if the URL parameter is absent' do
      visit new_project_issue_path(project)

      expect(page).not_to have_text 'Mark this item as related to'
    end

    context 'guest' do
      let(:current_user) { guest }

      it 'does not offer to link the new issue to an issue that the user does not have access to' do
        visit new_project_issue_path(project, { add_related_issue: confidential_issue.iid })

        expect(page).not_to have_text 'Mark this item as related to'
      end
    end

    it 'links the new issue and the issue of origin' do
      visit new_project_issue_path(project, { add_related_issue: issue.iid })

      expect(page).to have_checked_field("Mark this item as related to: issue \##{issue.iid}")
      expect(page).to have_link("\##{issue.iid}")

      fill_in 'Title', with: 'title'
      click_button 'Create issue'

      within_testid('work-item-relationships') do
        expect(page).to have_link(issue.title)
      end
    end

    it 'links the new incident and the incident of origin' do
      incident = create(:incident, project: project)
      visit new_project_issue_path(project, { add_related_issue: incident.iid })

      expect(page).to have_checked_field("Mark this item as related to: incident \##{incident.iid}")

      fill_in 'Title', with: 'title'
      click_button 'Create issue'

      within_testid('work-item-relationships') do
        expect(page).to have_link(incident.title)
      end
    end

    it 'does not link the new issue to any other issues if the checkbox is not checked' do
      visit new_project_issue_path(project, { add_related_issue: issue.iid })

      expect(page).to have_checked_field("Mark this item as related to: issue \##{issue.iid}")

      uncheck "Mark this item as related to: issue \##{issue.iid}"
      fill_in 'Title', with: 'title'
      click_button 'Create issue'

      within_testid('work-item-relationships') do
        expect(page).not_to have_link(issue.title)
      end
    end
  end

  describe 'sub-group project' do
    let(:group) { create(:group) }
    let(:nested_group_1) { create(:group, parent: group) }
    let(:sub_group_project) { create(:project, group: nested_group_1) }

    before do
      sub_group_project.add_maintainer(user)

      visit new_project_issue_path(sub_group_project)
    end

    context 'labels', :js do
      it 'creates project label from dropdown' do
        within_testid('work-item-labels') do
          click_button 'Edit'
          click_button _('Create project label')
          fill_in _('Label name'), with: 'test label'
          click_link 'Crimson'
          click_button 'Create'

          expect_listbox_item('test label')
        end
      end
    end
  end
end
