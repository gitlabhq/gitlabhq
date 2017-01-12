require 'rails_helper'

describe 'Filter merge requests', feature: true do
  include WaitForAjax

  let!(:project)   { create(:project) }
  let!(:group)     { create(:group) }
  let!(:user)      { create(:user)}
  let!(:milestone) { create(:milestone, project: project) }
  let!(:label)     { create(:label, project: project) }
  let!(:wontfix)   { create(:label, project: project, title: "Won't fix") }

  before do
    project.team << [user, :master]
    group.add_developer(user)
    login_as(user)
    create(:merge_request, source_project: project, target_project: project)
  end

  describe 'for assignee from mr#index' do
    before do
      visit namespace_project_merge_requests_path(project.namespace, project)

      find('.js-assignee-search').click

      find('.dropdown-menu-user-link', text: user.username).click

      wait_for_ajax
    end

    context 'assignee', js: true do
      it 'updates to current user' do
        expect(find('.js-assignee-search .dropdown-toggle-text')).to have_content(user.name)
      end

      it 'does not change when closed link is clicked' do
        find('.issues-state-filters a', text: "Closed").click

        expect(find('.js-assignee-search .dropdown-toggle-text')).to have_content(user.name)
      end

      it 'does not change when all link is clicked' do
        find('.issues-state-filters a', text: "All").click

        expect(find('.js-assignee-search .dropdown-toggle-text')).to have_content(user.name)
      end
    end
  end

  describe 'for milestone from mr#index' do
    before do
      visit namespace_project_merge_requests_path(project.namespace, project)

      find('.js-milestone-select').click

      find('.milestone-filter .dropdown-content a', text: milestone.title).click

      wait_for_ajax
    end

    context 'milestone', js: true do
      it 'updates to current milestone' do
        expect(find('.js-milestone-select .dropdown-toggle-text')).to have_content(milestone.title)
      end

      it 'does not change when closed link is clicked' do
        find('.issues-state-filters a', text: "Closed").click

        expect(find('.js-milestone-select .dropdown-toggle-text')).to have_content(milestone.title)
      end

      it 'does not change when all link is clicked' do
        find('.issues-state-filters a', text: "All").click

        expect(find('.js-milestone-select .dropdown-toggle-text')).to have_content(milestone.title)
      end
    end
  end

  describe 'for label from mr#index', js: true do
    before do
      visit namespace_project_merge_requests_path(project.namespace, project)
      find('.js-label-select').click
      wait_for_ajax
    end

    it 'filters by any label' do
      find('.dropdown-menu-labels a', text: 'Any Label').click
      page.first('.labels-filter .dropdown-title .dropdown-menu-close-icon').click
      wait_for_ajax

      expect(find('.labels-filter')).to have_content 'Label'
    end

    it 'filters by no label' do
      find('.dropdown-menu-labels a', text: 'No Label').click
      page.first('.labels-filter .dropdown-title .dropdown-menu-close-icon').click
      wait_for_ajax

      page.within '.labels-filter' do
        expect(page).to have_content 'Labels'
      end
      expect(find('.js-label-select .dropdown-toggle-text')).to have_content('Labels')
    end

    it 'filters by a label' do
      find('.dropdown-menu-labels a', text: label.title).click
      page.within '.labels-filter' do
        expect(page).to have_content label.title
      end
      expect(find('.js-label-select .dropdown-toggle-text')).to have_content(label.title)
    end

    it "filters by `won't fix` and another label" do
      page.within '.labels-filter' do
        click_link wontfix.title
        expect(page).to have_content wontfix.title
        click_link label.title
      end

      expect(find('.js-label-select .dropdown-toggle-text')).to have_content("#{wontfix.title} +1 more")
    end

    it "filters by `won't fix` label followed by another label after page load" do
      page.within '.labels-filter' do
        click_link wontfix.title
        expect(page).to have_content wontfix.title
      end

      find('body').click

      expect(find('.filtered-labels')).to have_content(wontfix.title)

      find('.js-label-select').click
      wait_for_ajax
      find('.dropdown-menu-labels a', text: label.title).click

      find('body').click

      expect(find('.filtered-labels')).to have_content(wontfix.title)
      expect(find('.filtered-labels')).to have_content(label.title)

      find('.js-label-select').click
      wait_for_ajax

      expect(find('.dropdown-menu-labels li', text: wontfix.title)).to have_css('.is-active')
      expect(find('.dropdown-menu-labels li', text: label.title)).to have_css('.is-active')
    end

    it "selects and unselects `won't fix`" do
      find('.dropdown-menu-labels a', text: wontfix.title).click
      find('.dropdown-menu-labels a', text: wontfix.title).click
      # Close label dropdown to load
      find('body').click
      expect(page).not_to have_css('.filtered-labels')
    end
  end

  describe 'for assignee and label from issues#index' do
    before do
      visit namespace_project_merge_requests_path(project.namespace, project)

      find('.js-assignee-search').click

      find('.dropdown-menu-user-link', text: user.username).click

      expect(page).not_to have_selector('.mr-list .merge-request')

      find('.js-label-select').click

      find('.dropdown-menu-labels .dropdown-content a', text: label.title).click
      page.first('.labels-filter .dropdown-title .dropdown-menu-close-icon').click

      wait_for_ajax
    end

    context 'assignee and label', js: true do
      it 'updates to current assignee and label' do
        expect(find('.js-assignee-search .dropdown-toggle-text')).to have_content(user.name)
        expect(find('.js-label-select .dropdown-toggle-text')).to have_content(label.title)
      end

      it 'does not change when closed link is clicked' do
        find('.issues-state-filters a', text: "Closed").click

        expect(find('.js-assignee-search .dropdown-toggle-text')).to have_content(user.name)
        expect(find('.js-label-select .dropdown-toggle-text')).to have_content(label.title)
      end

      it 'does not change when all link is clicked' do
        find('.issues-state-filters a', text: "All").click

        expect(find('.js-assignee-search .dropdown-toggle-text')).to have_content(user.name)
        expect(find('.js-label-select .dropdown-toggle-text')).to have_content(label.title)
      end
    end
  end

  describe 'filter merge requests by text' do
    before do
      create(:merge_request, title: "Bug", source_project: project, target_project: project, source_branch: "bug")

      bug_label = create(:label, project: project, title: 'bug')
      milestone = create(:milestone, title: "8", project: project)

      mr = create(:merge_request, 
        title: "Bug 2", 
        source_project: project, 
        target_project: project, 
        source_branch: "bug2", 
        milestone: milestone,
        author: user,
        assignee: user)
      mr.labels << bug_label

      visit namespace_project_merge_requests_path(project.namespace, project)
    end

    context 'only text', js: true do
      it 'filters merge requests by searched text' do
        fill_in 'issuable_search', with: 'Bug'

        page.within '.mr-list' do
          expect(page).to have_selector('.merge-request', count: 2)
        end
      end

      it 'does not show any merge requests' do
        fill_in 'issuable_search', with: 'testing'

        page.within '.mr-list' do
          expect(page).not_to have_selector('.merge-request')
        end
      end
    end

    context 'text and dropdown options', js: true do
      it 'filters by text and label' do
        fill_in 'issuable_search', with: 'Bug'

        expect(page).to have_issuable_counts(open: 2, closed: 0, all: 2)
        page.within '.mr-list' do
          expect(page).to have_selector('.merge-request', count: 2)
        end

        click_button 'Label'
        page.within '.labels-filter' do
          click_link 'bug'
        end
        find('.dropdown-menu-close-icon').click

        expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
        page.within '.mr-list' do
          expect(page).to have_selector('.merge-request', count: 1)
        end
      end

      it 'filters by text and milestone' do
        fill_in 'issuable_search', with: 'Bug'

        expect(page).to have_issuable_counts(open: 2, closed: 0, all: 2)
        page.within '.mr-list' do
          expect(page).to have_selector('.merge-request', count: 2)
        end

        click_button 'Milestone'
        page.within '.milestone-filter' do
          click_link '8'
        end

        expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
        page.within '.mr-list' do
          expect(page).to have_selector('.merge-request', count: 1)
        end
      end

      it 'filters by text and assignee' do
        fill_in 'issuable_search', with: 'Bug'

        expect(page).to have_issuable_counts(open: 2, closed: 0, all: 2)
        page.within '.mr-list' do
          expect(page).to have_selector('.merge-request', count: 2)
        end

        click_button 'Assignee'
        page.within '.dropdown-menu-assignee' do
          click_link user.name
        end

        expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
        page.within '.mr-list' do
          expect(page).to have_selector('.merge-request', count: 1)
        end
      end

      it 'filters by text and author' do
        fill_in 'issuable_search', with: 'Bug'

        expect(page).to have_issuable_counts(open: 2, closed: 0, all: 2)
        page.within '.mr-list' do
          expect(page).to have_selector('.merge-request', count: 2)
        end

        click_button 'Author'
        page.within '.dropdown-menu-author' do
          click_link user.name
        end

        expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
        page.within '.mr-list' do
          expect(page).to have_selector('.merge-request', count: 1)
        end
      end
    end
  end

  describe 'filter merge requests and sort', js: true do
    before do
      bug_label = create(:label, project: project, title: 'bug')

      mr1 = create(:merge_request, title: "Frontend", source_project: project, target_project: project, source_branch: "Frontend")
      mr2 = create(:merge_request, title: "Bug 2", source_project: project, target_project: project, source_branch: "bug2")

      mr1.labels << bug_label
      mr2.labels << bug_label

      visit namespace_project_merge_requests_path(project.namespace, project)
    end

    it 'is able to filter and sort merge requests' do
      click_button 'Label'
      wait_for_ajax
      page.within '.labels-filter' do
        click_link 'bug'
      end
      find('.dropdown-menu-close-icon').click
      wait_for_ajax

      expect(page).to have_issuable_counts(open: 2, closed: 0, all: 2)
      page.within '.mr-list' do
        expect(page).to have_selector('.merge-request', count: 2)
      end

      click_button 'Last created'
      page.within '.dropdown-menu-sort' do
        click_link 'Oldest created'
      end
      wait_for_ajax

      page.within '.mr-list' do
        expect(page).to have_content('Frontend')
      end
    end
  end
end
