# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Navigation menu item pinning', :js, feature_category: :navigation do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, developers: user) }

  before do
    sign_in(user)
  end

  describe 'non-pinnable navigation menu' do
    before do
      visit explore_projects_path
    end

    it 'does not show the Pinned section nor buttons to pin items' do
      within '#super-sidebar' do
        expect(page).not_to have_content 'Pinned'
      end

      within '#super-sidebar' do
        expect(page).not_to have_css 'button svg[data-testid="thumbtack-icon"]'
      end
    end
  end

  describe 'pinnable navigation menu' do
    before do
      visit project_path(project)
    end

    it 'adds sensible defaults' do
      within_testid 'pinned-nav-items' do
        expect(page).to have_link 'Issues'
      end
    end

    it 'shows the Pinned section' do
      within '#super-sidebar' do
        expect(page).to have_content 'Pinned'
      end
    end

    it 'allows to pin items' do
      within '#super-sidebar' do
        click_on 'Manage'
        add_pin('Activity')
        add_pin('Members')
      end

      within_testid 'pinned-nav-items' do
        expect(page).to have_link 'Issues'
        expect(page).to have_link 'Activity'
        expect(page).to have_link 'Members'
      end
    end

    describe 'when all pins are removed' do
      before do
        remove_pin('Issues')
      end

      it 'shows the Pinned section as expanded by default' do
        within '#super-sidebar' do
          expect(page).to have_content 'Your pinned items appear here.'
        end
      end

      it 'maintains the collapsed/expanded state between page loads' do
        within '#super-sidebar' do
          click_on 'Pinned'
          visit project_path(project)
          expect(page).not_to have_content 'Your pinned items appear here.'

          click_on 'Pinned'
          visit project_path(project)
          expect(page).to have_content 'Your pinned items appear here.'
        end
      end
    end

    describe 'pinned items' do
      before do
        within '#super-sidebar' do
          click_on 'Operate'
          add_pin('Terraform states')
          add_pin('Terraform modules')
          wait_for_requests
        end
      end

      it 'can be unpinned from within the pinned section' do
        within_testid 'pinned-nav-items' do
          remove_pin('Terraform states')
          expect(page).not_to have_content 'Terraform states'
        end
      end

      it 'can be unpinned from within its section' do
        section = find("button", text: 'Operate')

        within(section.sibling('div')) do
          remove_pin('Terraform modules')
        end

        within_testid 'pinned-nav-items' do
          expect(page).not_to have_content 'Terraform modules'
        end
      end

      it 'can be reordered' do
        within_testid 'pinned-nav-items' do
          pinned_items = page.find_all('a', wait: false).map(&:text)
          item2 = page.find('a', text: 'Terraform states')
          item3 = page.find('a', text: 'Terraform modules')
          expect(pinned_items[1..2]).to eq [item2.text, item3.text]
          drag_item(item3, to: item2)

          pinned_items = page.find_all('a', wait: false).map(&:text)
          expect(pinned_items[1..2]).to eq [item3.text, item2.text]
        end
      end
    end
  end

  describe 'reordering pins with hidden pins from non-available features' do
    let_it_be(:project_with_repo) { create(:project, :repository, developers: user) }
    let_it_be(:project_without_repo) { create(:project, :repository_disabled, developers: user) }

    before do
      visit project_path(project_with_repo)
      within '#super-sidebar' do
        click_on 'Code'
        add_pin('Commits')
        click_on 'Manage'
        add_pin('Activity')
        add_pin('Members')
      end

      visit project_path(project_without_repo)
      within_testid 'pinned-nav-items' do
        activity_item = page.find('a', text: 'Activity')
        members_item = page.find('a', text: 'Members')
        drag_item(members_item, to: activity_item)
      end

      visit project_path(project_with_repo)
    end

    it 'keeps pins of non-available features' do
      within_testid 'pinned-nav-items' do
        pinned_items = page.find_all('a', wait: false)
          .map(&:text)
          .map { |text| text.split("\n").first } # to drop the counter badge text from "Issues\n0"
        expect(pinned_items).to eq ["Issues", "Merge requests", "Commits", "Members", "Activity"]
      end
    end
  end

  describe 'section collapse states after using a pinned item to navigate' do
    before do
      project.add_member(user, :owner)
      visit project_path(project)
    end

    context 'when a pinned item is clicked in the Pinned section' do
      before do
        within_testid 'pinned-nav-items' do
          click_on 'Issues'
        end
      end

      it 'shows the Pinned section as expanded and the original section as collapsed' do
        within_testid 'pinned-nav-items' do
          expect(page).to have_link 'Issues'
        end

        within '#menu-section-button-plan' do
          expect(page).not_to have_link 'Issues'
        end
      end
    end

    context 'when a pinned item is clicked in its original section' do
      before do
        within '#super-sidebar' do
          click_on 'Plan'
        end
        within '#super-sidebar #plan' do
          click_on 'Issues'
        end
      end

      it 'shows the Pinned section as collapsed and the original section as expanded' do
        within '#menu-section-button-plan' do
          expect(page).not_to have_link 'Issues'
        end
        within '#super-sidebar #plan' do
          expect(page).to have_link 'Issues'
        end
      end
    end
  end

  private

  def add_pin(nav_item_title)
    nav_item = find_by_testid('nav-item', text: nav_item_title)
    scroll_to(nav_item)
    nav_item.hover
    find_by_testid('nav-item-pin', context: nav_item).click

    wait_for_requests
  end

  def remove_pin(nav_item_title)
    nav_item = find_by_testid('nav-item', text: nav_item_title)
    scroll_to(nav_item)
    nav_item.hover
    find_by_testid('nav-item-unpin', context: nav_item).click

    wait_for_requests
  end

  def drag_item(item, to:)
    item.hover

    # Reduce delay to make it less likely for draggables to
    # change position during drag operation, which reduces
    # flakiness.
    find_by_testid('grip-icon', context: item).drag_to(to, delay: 0.01)

    wait_for_requests
  end
end
