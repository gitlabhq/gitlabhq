require 'rails_helper'

describe 'New/edit issue', feature: true, js: true do
  include GitlabRoutingHelper
  include ActionView::Helpers::JavaScriptHelper

  let!(:project)   { create(:project) }
  let!(:user)      { create(:user)}
  let!(:user2)     { create(:user)}
  let!(:milestone) { create(:milestone, project: project) }
  let!(:label)     { create(:label, project: project) }
  let!(:label2)    { create(:label, project: project) }
  let!(:issue)     { create(:issue, project: project, assignees: [user], milestone: milestone) }

  before do
    project.team << [user, :master]
    project.team << [user2, :master]
    login_as(user)
  end

  context 'new issue' do
    before do
      visit new_namespace_project_issue_path(project.namespace, project)
    end

    describe 'multiple assignees' do
      before do
        click_button 'Unassigned'
      end

      it 'unselects other assignees when unassigned is selected' do
        page.within '.dropdown-menu-user' do
          click_link user2.name
        end

        page.within '.dropdown-menu-user' do
          click_link 'Unassigned'
        end

        page.within '.js-assignee-search' do
          expect(page).to have_content 'Unassigned'
        end

        expect(find('input[name="issue[assignee_ids][]"]', visible: false).value).to match('0')
      end

      it 'toggles assign to me when current user is selected and unselected' do
        page.within '.dropdown-menu-user' do
          click_link user.name
        end

        expect(find('a', text: 'Assign to me', visible: false)).not_to be_visible

        page.within '.dropdown-menu-user' do
          click_link user.name
        end

        expect(find('a', text: 'Assign to me')).to be_visible
      end
    end

    it 'allows user to create new issue' do
      fill_in 'issue_title', with: 'title'
      fill_in 'issue_description', with: 'title'

      expect(find('a', text: 'Assign to me')).to be_visible
      click_button 'Unassigned'
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

      page.within '.issuable-meta' do
        issue = Issue.find_by(title: 'title')

        expect(page).to have_text("Issue #{issue.to_reference}")
        # compare paths because the host differ in test
        expect(find_link(issue.to_reference)[:href]).to end_with(issue_path(issue))
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

    it 'correctly updates the selected user when changing assignee' do
      click_button 'Unassigned'
      page.within '.dropdown-menu-user' do
        click_link user.name
      end

      expect(find('input[name="issue[assignee_ids][]"]', visible: false).value).to match(user.id.to_s)

      click_button user.name

      expect(find('.dropdown-menu-user a.is-active').first(:xpath, '..')['data-user-id']).to eq(user.id.to_s)

      # check the ::before pseudo element to ensure checkmark icon is present
      expect(before_for_selector('.dropdown-menu-selectable a.is-active')).not_to eq('')
      expect(before_for_selector('.dropdown-menu-selectable a:not(.is-active)')).to eq('')

      page.within '.dropdown-menu-user' do
        click_link user2.name
      end

      expect(find('input[name="issue[assignee_ids][]"]', visible: false).value).to match(user2.id.to_s)

      click_button user2.name

      expect(find('.dropdown-menu-user a.is-active').first(:xpath, '..')['data-user-id']).to eq(user2.id.to_s)
    end
  end

  context 'edit issue' do
    before do
      visit edit_namespace_project_issue_path(project.namespace, project, issue)
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
