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

    sign_in(current_user)
  end

  describe 'new issue' do
    before do
      visit new_project_issue_path(project)
    end

    describe 'shorten users API pagination limit' do
      before do
        # Using `allow_any_instance_of`/`and_wrap_original`, `original` would
        # somehow refer to the very block we defined to _wrap_ that method, instead of
        # the original method, resulting in infinite recursion when called.
        # This is likely a bug with helper modules included into dynamically generated view classes.
        # To work around this, we have to hold on to and call to the original implementation manually.
        original_issue_dropdown_options = FormHelper.instance_method(:assignees_dropdown_options)
        allow_any_instance_of(FormHelper).to receive(:assignees_dropdown_options).and_wrap_original do |original, *args|
          options = original_issue_dropdown_options.bind_call(original.receiver, *args)
          options[:data][:per_page] = 2

          options
        end

        visit new_project_issue_path(project)

        click_button 'Unassigned'

        wait_for_requests
      end

      it 'displays selected users even if they are not part of the original API call' do
        find('.dropdown-input-field').native.send_keys user2.name

        page.within '.dropdown-menu-user' do
          expect(page).to have_content user2.name
          click_link user2.name
        end

        click_button user2.name

        page.within '.dropdown-menu-user' do
          expect(page).to have_content user.name
          expect(find('.dropdown-menu-user a.is-active').first(:xpath, '..')['data-user-id']).to eq(user2.id.to_s)
        end
      end
    end

    describe 'single assignee' do
      before do
        click_button 'Unassigned'

        wait_for_requests
      end

      it 'unselects other assignees when unassigned is selected' do
        page.within '.dropdown-menu-user' do
          click_link user2.name
        end

        click_button user2.name

        page.within '.dropdown-menu-user' do
          click_link 'Unassigned'
        end

        expect(find('input[name="issue[assignee_ids][]"]', visible: false).value).to match('0')
      end

      it 'toggles assign to me when current user is selected and unselected' do
        page.within '.dropdown-menu-user' do
          click_link user.name
        end

        expect(find('a', text: 'Assign to me', visible: false)).not_to be_visible

        click_button user.name

        page.within('.dropdown-menu-user') do
          click_link user.name
        end

        expect(page.find('.dropdown-menu-user', visible: false)).not_to be_visible
      end
    end

    it 'allows user to create new issue' do
      fill_in 'issue_title', with: 'title'
      fill_in 'issue_description', with: 'title'

      expect(find('a', text: 'Assign to me')).to be_visible
      click_button 'Unassigned'

      wait_for_requests

      page.within '.dropdown-menu-user' do
        click_link user2.name
      end
      expect(find('input[name="issue[assignee_ids][]"]', visible: false).value).to match(user2.id.to_s)
      page.within '.js-assignee-search' do
        expect(page).to have_content user2.name
      end
      expect(find('a', text: 'Assign to me')).to be_visible

      click_link 'Assign to me'
      assignee_ids = page.all('input[name="issue[assignee_ids][]"]', visible: false)

      expect(assignee_ids[0].value).to match(user.id.to_s)

      page.within '.js-assignee-search' do
        expect(page).to have_content user.name
      end
      expect(find('a', text: 'Assign to me', visible: false)).not_to be_visible

      click_button 'Select milestone'
      click_button milestone.title
      expect(find('input[name="issue[milestone_id]"]', visible: false).value).to match(milestone.id.to_s)
      expect(page).to have_button milestone.title

      click_button _('Select label')
      wait_for_all_requests
      within_testid('sidebar-labels') do
        click_button label.title
        click_button label2.title
        click_button _('Close')
        wait_for_requests
        within_testid('embedded-labels-list') do
          expect(page).to have_content(label.title)
          expect(page).to have_content(label2.title)
        end
      end

      click_button 'Create issue'

      page.within '.issuable-sidebar' do
        page.within '.assignee' do
          expect(page).to have_content "Assignee"
        end

        page.within '.milestone' do
          expect(page).to have_content milestone.title
        end

        page.within '.labels' do
          expect(page).to have_content label.title
          expect(page).to have_content label2.title
        end
      end

      within_testid 'breadcrumb-links' do
        issue = Issue.find_by(title: 'title')

        expect(page).to have_text("Issues #{issue.to_reference}")
      end
    end

    it 'correctly updates the dropdown toggle when removing a label' do
      click_button _('Select label')

      wait_for_all_requests

      within_testid 'sidebar-labels' do
        click_button label.title
        click_button _('Close')

        wait_for_requests

        within_testid('embedded-labels-list') do
          expect(page).to have_content(label.title)
        end

        expect(page.find('.gl-dropdown-button-text')).to have_content(label.title)
      end

      click_button label.title, class: 'gl-dropdown-toggle'

      wait_for_all_requests

      within_testid 'sidebar-labels' do
        click_button label.title, class: 'dropdown-item'
        click_button _('Close')

        wait_for_requests

        expect(page).not_to have_selector('[data-testid="embedded-labels-list"]')
        expect(page.find('.gl-dropdown-button-text')).to have_content(_('Select label'))
      end
    end

    it 'clears label search input field when a label is selected', :js do
      click_button _('Select label')

      wait_for_all_requests

      within_testid 'sidebar-labels' do
        search_field = find('input[type="search"]')

        search_field.native.send_keys(label.title)

        expect(page).to have_css('.gl-search-box-by-type-clear')

        click_button label.title, class: 'dropdown-item'

        expect(page).not_to have_css('.gl-search-box-by-type-clear')
        expect(search_field.value).to eq ''
      end
    end

    it 'displays an error message when submitting an invalid form' do
      click_button 'Create issue'

      within_testid('issue-title-input-field') do
        expect(page).to have_text(_('This field is required.'))
      end
    end

    it 'correctly updates the selected user when changing assignee' do
      click_button 'Unassigned'

      wait_for_requests

      page.within '.dropdown-menu-user' do
        click_link user.name
      end

      expect(find('.js-assignee-search')).to have_content(user.name)
      click_button user.name

      page.within '.dropdown-menu-user' do
        click_link user2.name
      end

      expect(find('.js-assignee-search')).to have_content(user2.name)
    end

    it 'description has autocomplete' do
      find('#issue_description').native.send_keys('')
      fill_in 'issue_description', with: '@'

      expect(page).to have_selector('.atwho-view')
    end

    describe 'displays issue type options in the dropdown' do
      shared_examples 'type option is visible' do |label:, identifier:|
        it "shows #{identifier} option", :aggregate_failures do
          wait_for_requests
          expect_listbox_item(label)
        end
      end

      shared_examples 'type option is missing' do |label:, identifier:|
        it "does not show #{identifier} option", :aggregate_failures do
          wait_for_requests
          expect_no_listbox_item(label)
        end
      end

      before do
        page.within('.issue-form') do
          click_button 'Issue'
        end
      end

      context 'when user is guest' do
        let_it_be(:guest) { create(:user) }

        let(:current_user) { guest }

        before_all do
          project.add_guest(guest)
        end

        it_behaves_like 'type option is visible', label: 'Issue', identifier: :issue
        it_behaves_like 'type option is missing', label: 'Incident', identifier: :incident
      end

      context 'when user is reporter' do
        let_it_be(:reporter) { create(:user) }

        let(:current_user) { reporter }

        before_all do
          project.add_reporter(reporter)
        end

        it_behaves_like 'type option is visible', label: 'Issue', identifier: :issue
        it_behaves_like 'type option is visible', label: 'Incident', identifier: :incident
      end
    end

    describe 'milestone' do
      let!(:milestone) do
        create(:milestone, title: '">&lt;img src=x onerror=alert(document.domain)&gt;', project: project)
      end

      it 'escapes milestone' do
        click_button 'Select milestone'
        click_button milestone.title

        page.within '.issue-milestone' do
          expect(page).to have_button milestone.title
          expect(page).not_to have_selector 'img'
        end
      end
    end

    describe 'when repository contains CONTRIBUTING.md' do
      it 'has contribution guidelines prompt' do
        text = _('Please review the %{linkStart}contribution guidelines%{linkEnd} for this project.') % { linkStart: nil, linkEnd: nil }
        expect(find('#new_issue')).to have_text(text)
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

      expect(find('#issue_description').value).to be_empty
    end

    it 'fills the description from the issue[description] query parameter' do
      visit new_project_issue_path(project, issue: { description: 'description from query parameter' })

      expect(find('#issue_description').value).to match('description from query parameter')
    end

    it 'fills the description from the issuable_template query parameter', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/388728' do
      visit new_project_issue_path(project, issuable_template: 'test_template')
      wait_for_requests

      expect(find('#issue_description').value).to match('description from template')
    end

    it 'fills the description from the issuable_template and issue[description] query parameters', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/388728' do
      visit new_project_issue_path(project, issuable_template: 'test_template', issue: { description: 'description from query parameter' })
      wait_for_requests

      expect(find('#issue_description').value).to match('description from template\ndescription from query parameter')
    end
  end

  describe 'new issue from related issue' do
    it 'does not offer to link the new issue to any other issues if the URL parameter is absent' do
      visit new_project_issue_path(project)
      expect(page).not_to have_selector '#add_related_issue'
      expect(page).not_to have_text "Relate to"
    end

    context 'guest' do
      let(:current_user) { guest }

      it 'does not offer to link the new issue to an issue that the user does not have access to' do
        visit new_project_issue_path(project, { add_related_issue: confidential_issue.iid })
        expect(page).not_to have_selector '#add_related_issue'
        expect(page).not_to have_text "Relate to"
      end
    end

    it 'links the new issue and the issue of origin' do
      visit new_project_issue_path(project, { add_related_issue: issue.iid })
      expect(page).to have_selector '#add_related_issue'
      expect(page).to have_text "Relate to issue \##{issue.iid}"
      expect(page).to have_text 'Adds this issue as related to the issue it was created from'
      fill_in 'issue_title', with: 'title'
      click_button 'Create issue'
      page.within '#related-issues' do
        expect(page).to have_text "\##{issue.iid}"
      end
    end

    it 'links the new incident and the incident of origin' do
      incident = create(:incident, project: project)
      visit new_project_issue_path(project, { add_related_issue: incident.iid })
      expect(page).to have_selector '#add_related_issue'
      expect(page).to have_text "Relate to incident \##{incident.iid}"
      expect(page).to have_text 'Adds this incident as related to the incident it was created from'
      fill_in 'issue_title', with: 'title'
      click_button 'Create issue'
      page.within '#related-issues' do
        expect(page).to have_text "\##{incident.iid}"
      end
    end

    it 'does not link the new issue to any other issues if the checkbox is not checked' do
      visit new_project_issue_path(project, { add_related_issue: issue.iid })
      expect(page).to have_selector '#add_related_issue'
      expect(page).to have_text "Relate to issue \##{issue.iid}"
      uncheck "Relate to issue \##{issue.iid}"
      fill_in 'issue_title', with: 'title'
      click_button 'Create issue'
      page.within '#related-issues' do
        expect(page).not_to have_text "\##{issue.iid}"
      end
    end
  end

  describe 'edit issue' do
    before do
      visit edit_project_issue_path(project, issue)
    end

    it 'allows user to update issue', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/435787' do
      expect(find('input[name="issue[assignee_ids][]"]', visible: false).value).to match(user.id.to_s)
      expect(find('input[name="issue[milestone_id]"]', visible: false).value).to match(milestone.id.to_s)
      expect(find('a', text: 'Assign to me', visible: false)).not_to be_visible

      page.within '.js-user-search' do
        expect(page).to have_content user.name
      end

      expect(page).to have_button milestone.title

      click_button _('Select label')

      wait_for_all_requests

      within_testid 'sidebar-labels' do
        click_button label.title
        click_button label2.title
        click_button _('Close')

        wait_for_requests

        within_testid('embedded-labels-list') do
          expect(page).to have_content(label.title)
          expect(page).to have_content(label2.title)
        end
      end

      expect(page.all('input[name="issue[label_ids][]"]', visible: false)
        .map(&:value))
        .to contain_exactly(label.id.to_s, label2.id.to_s)

      click_button 'Save changes'

      page.within '.issuable-sidebar' do
        page.within '.assignee' do
          expect(page).to have_content user.name
        end

        page.within '.milestone' do
          expect(page).to have_content milestone.title
        end

        page.within '.labels' do
          expect(page).to have_content label.title
          expect(page).to have_content label2.title
        end
      end
    end

    it 'description has autocomplete' do
      find('#issue_description').native.send_keys('')
      fill_in 'issue_description', with: '@'

      expect(page).to have_selector('.atwho-view')
    end
  end

  describe 'editing an issue by hotkey' do
    let_it_be(:issue2) { create(:issue, project: project) }

    before do
      visit project_issue_path(project, issue2)
    end

    it 'opens inline edit form with shortcut' do
      find('body').send_keys('e')

      expect(page).to have_selector('.detail-page-description form')
    end

    context 'when user has made no changes' do
      it 'let user leave the page without warnings' do
        expected_content = 'Issue created'
        expect(page).to have_content(expected_content)

        find('body').send_keys('e')

        click_link 'Homepage'

        expect(page).not_to have_content(expected_content)
      end
    end

    context 'when user has made changes' do
      it 'shows a warning and can stay on page' do
        content = 'new issue content'

        find('body').send_keys('e')
        fill_in 'issue-description', with: content

        click_link 'Homepage' do
          page.driver.browser.switch_to.alert.dismiss
        end

        click_button 'Save changes'
        wait_for_requests

        expect(page).to have_content(content)
      end

      it 'shows a warning and can leave page' do
        content = 'new issue content'
        find('body').send_keys('e')
        fill_in 'issue-description', with: content

        click_link 'Homepage' do
          page.driver.browser.switch_to.alert.dismiss
        end

        expect(page).not_to have_content(content)
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
      it 'creates project label from dropdown', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/416585' do
        find('[data-testid="labels-select-dropdown-contents"] button').click

        wait_for_all_requests

        within_testid 'sidebar-labels' do
          click_button _('Create project label')
          fill_in _('Label name'), with: 'test label'
          first('.suggest-colors-dropdown a').click
          click_button 'Create'
        end

        page.within '.js-labels-list' do
          expect(page).to have_button 'test label'
        end
      end
    end
  end
end
