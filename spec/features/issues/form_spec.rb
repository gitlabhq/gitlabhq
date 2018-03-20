require 'rails_helper'

describe 'New/edit issue', :js do
  include ActionView::Helpers::JavaScriptHelper
  include FormHelper

  let!(:project)   { create(:project) }
  let!(:user)      { create(:user)}
  let!(:user2)     { create(:user)}
  let!(:milestone) { create(:milestone, project: project) }
  let!(:label)     { create(:label, project: project) }
  let!(:label2)    { create(:label, project: project) }
  let!(:issue)     { create(:issue, project: project, assignees: [user], milestone: milestone) }

  before do
    project.add_master(user)
    project.add_master(user2)
    sign_in(user)
  end

  context 'new issue' do
    before do
      visit new_project_issue_path(project)
    end

    describe 'shorten users API pagination limit' do
      before do
        # Using `allow_any_instance_of`/`and_wrap_original`, `original` would
        # somehow refer to the very block we defined to _wrap_ that method, instead of
        # the original method, resulting in infinite recurison when called.
        # This is likely a bug with helper modules included into dynamically generated view classes.
        # To work around this, we have to hold on to and call to the original implementation manually.
        original_issue_dropdown_options = FormHelper.instance_method(:issue_assignees_dropdown_options)
        allow_any_instance_of(FormHelper).to receive(:issue_assignees_dropdown_options).and_wrap_original do |original, *args|
          options = original_issue_dropdown_options.bind(original.receiver).call(*args)
          options[:data][:per_page] = 2

          options
        end

        visit new_project_issue_path(project)

        click_button 'Unassigned'

        wait_for_requests
      end

      it 'should display selected users even if they are not part of the original API call' do
        find('.dropdown-input-field').native.send_keys user2.name

        page.within '.dropdown-menu-user' do
          expect(page).to have_content user2.name
          click_link user2.name
        end

        find('.js-assignee-search').click
        find('.js-dropdown-input-clear').click

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

      click_button 'Milestone'
      page.within '.issue-milestone' do
        click_link milestone.title
      end
      expect(find('input[name="issue[milestone_id]"]', visible: false).value).to match(milestone.id.to_s)
      page.within '.js-milestone-select' do
        expect(page).to have_content milestone.title
      end

      click_button 'Labels'
      page.within '.dropdown-menu-labels' do
        click_link label.title
        click_link label2.title
      end
      page.within '.js-label-select' do
        expect(page).to have_content label.title
      end
      expect(page.all('input[name="issue[label_ids][]"]', visible: false)[1].value).to match(label.id.to_s)
      expect(page.all('input[name="issue[label_ids][]"]', visible: false)[2].value).to match(label2.id.to_s)

      click_button 'Submit issue'

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

      page.within '.breadcrumbs' do
        issue = Issue.find_by(title: 'title')

        expect(page).to have_text("Issues #{issue.to_reference}")
      end
    end

    it 'correctly updates the dropdown toggle when removing a label' do
      click_button 'Labels'

      page.within '.dropdown-menu-labels' do
        click_link label.title
      end

      expect(find('.js-label-select')).to have_content(label.title)

      page.within '.dropdown-menu-labels' do
        click_link label.title
      end

      expect(find('.js-label-select')).to have_content('Labels')
    end

    it 'clears label search input field when a label is selected' do
      click_button 'Labels'

      page.within '.dropdown-menu-labels' do
        search_field = find('input[type="search"]')

        search_field.set(label2.title)
        click_link label2.title
        expect(search_field.value).to eq ''
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

    describe 'milestone' do
      let!(:milestone) { create(:milestone, title: '">&lt;img src=x onerror=alert(document.domain)&gt;', project: project) }

      it 'escapes milestone' do
        click_button 'Milestone'

        page.within '.issue-milestone' do
          click_link milestone.title
        end

        page.within '.js-milestone-select' do
          expect(page).to have_content milestone.title
          expect(page).not_to have_selector 'img'
        end
      end
    end
  end

  context 'edit issue' do
    before do
      visit edit_project_issue_path(project, issue)
    end

    it 'allows user to update issue' do
      expect(find('input[name="issue[assignee_ids][]"]', visible: false).value).to match(user.id.to_s)
      expect(find('input[name="issue[milestone_id]"]', visible: false).value).to match(milestone.id.to_s)
      expect(find('a', text: 'Assign to me', visible: false)).not_to be_visible

      page.within '.js-user-search' do
        expect(page).to have_content user.name
      end

      page.within '.js-milestone-select' do
        expect(page).to have_content milestone.title
      end

      click_button 'Labels'
      page.within '.dropdown-menu-labels' do
        click_link label.title
        click_link label2.title
      end
      page.within '.js-label-select' do
        expect(page).to have_content label.title
      end
      expect(page.all('input[name="issue[label_ids][]"]', visible: false)[1].value).to match(label.id.to_s)
      expect(page.all('input[name="issue[label_ids][]"]', visible: false)[2].value).to match(label2.id.to_s)

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

  context 'inline edit' do
    before do
      visit project_issue_path(project, issue)
    end

    it 'opens inline edit form with shortcut' do
      find('body').send_keys('e')

      expect(page).to have_selector('.detail-page-description form')
    end
  end

  describe 'sub-group project' do
    let(:group) { create(:group) }
    let(:nested_group_1) { create(:group, parent: group) }
    let(:sub_group_project) { create(:project, group: nested_group_1) }

    before do
      sub_group_project.add_master(user)

      visit new_project_issue_path(sub_group_project)
    end

    it 'creates new label from dropdown' do
      click_button 'Labels'

      click_link 'Create new label'

      page.within '.dropdown-new-label' do
        fill_in 'new_label_name', with: 'test label'
        first('.suggest-colors-dropdown a').click

        click_button 'Create'

        wait_for_requests
      end

      page.within '.dropdown-menu-labels' do
        expect(page).to have_link 'test label'
      end
    end
  end

  def before_for_selector(selector)
    js = <<-JS.strip_heredoc
      (function(selector) {
        var el = document.querySelector(selector);
        return window.getComputedStyle(el, '::before').getPropertyValue('content');
      })("#{escape_javascript(selector)}")
    JS
    page.evaluate_script(js)
  end
end
