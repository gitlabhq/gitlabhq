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
        expect(page).to have_link 'Work items'
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
        expect(page).to have_link 'Work items'
        expect(page).to have_link 'Activity'
        expect(page).to have_link 'Members'
      end
    end

    describe 'when all pins are removed' do
      before do
        remove_pin('Work items')
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

  describe 'keyboard behavior in pinnable navigation menu' do
    before do
      visit project_path(project)
    end

    it 'adds sensible defaults' do
      within_testid 'pinned-nav-items' do
        expect(page).to have_link 'Work items'
      end
    end

    it 'shows the Pinned section' do
      within '#super-sidebar' do
        expect(page).to have_content 'Pinned'
      end
    end

    it 'allows to pin and unpin items with keyboard' do
      within '#super-sidebar' do
        find(:button, id: 'menu-section-button-manage').base.send_keys(:enter)
        send_keys :tab, :tab
        send_keys :enter
        send_keys :tab, :tab
        send_keys :enter
      end

      within_testid 'pinned-nav-items' do
        expect(page).to have_link 'Work items'
        expect(page).to have_link 'Activity'
        expect(page).to have_link 'Members'
      end

      within '#super-sidebar' do
        find(:button, id: 'menu-section-button-pinned').base
        send_keys :tab, :tab
        send_keys :space
        send_keys :tab, :tab
        send_keys :space
      end

      within_testid 'pinned-nav-items' do
        expect(page).to have_link 'Members'
      end
    end
  end

  describe 'keyboard behavior with collapsed sidebar' do
    before do
      visit project_path(project)
      # Collapse the sidebar to icon-only mode
      find_by_testid('super-sidebar-collapse-button').click
      wait_for_requests
    end

    it 'opens and closes flyout menu with Enter key' do
      find(:button, id: 'menu-section-button-manage').base.send_keys(:enter)
      expect(page).to have_css('#menu-section-button-manage-flyout', visible: :visible)
      send_keys(:escape)
      expect(page).not_to have_css('#menu-section-button-manage-flyout', visible: :visible)
    end

    it 'opens and closes flyout menu with Space key' do
      find(:button, id: 'menu-section-button-manage').base.send_keys(:space)
      expect(page).to have_css('#menu-section-button-manage-flyout', visible: :visible)
      send_keys(:escape)
      expect(page).not_to have_css('#menu-section-button-manage-flyout', visible: :visible)
    end

    it 'returns focus to section button after closing flyout with Escape' do
      find(:button, id: 'menu-section-button-manage')
        .base
        .send_keys(:enter)
      send_keys(:tab)
      send_keys(:escape)
      expect(page).not_to have_css('#menu-section-button-manage-flyout', visible: :visible)
      expect(page.find(':focus')).to eq(find('#menu-section-button-manage'))
    end

    it 'pins item from flyout menu using Enter key' do
      find(:button, id: 'menu-section-button-operate')
        .base
        .send_keys(:enter)
      send_keys :tab
      send_keys :tab
      send_keys :enter
      wait_for_requests
      send_keys(:escape)

      # Verify item is pinned
      find(:button, id: 'menu-section-button-pinned').base.send_keys(:enter)
      within '#menu-section-button-pinned-flyout' do
        expect(page).to have_link 'Environments'
      end
    end

    it 'removes pinned item from pinned section using Space key' do
      find(:button, id: 'menu-section-button-operate')
        .base
        .send_keys(:enter)
      send_keys :tab
      send_keys :tab
      send_keys :enter
      wait_for_requests
      send_keys(:escape)

      # Verify item is pinned
      find(:button, id: 'menu-section-button-pinned').base.send_keys(:enter)
      within '#menu-section-button-pinned-flyout' do
        expect(page).to have_link 'Environments'
      end

      # Now remove it from the pinned section using keyboard
      find(:button, id: 'menu-section-button-pinned').base
      # live_debug
      send_keys :tab
      send_keys :tab
      send_keys :tab
      send_keys :tab
      send_keys :enter
      wait_for_requests

      # Verify item is pinned
      within '#menu-section-button-pinned-flyout' do
        expect(page).not_to have_link 'Environments'
      end
    end
  end

  describe 'mouse behavior with collapsed sidebar' do
    before do
      visit project_path(project)
      # Collapse the sidebar to icon-only mode
      find_by_testid('super-sidebar-collapse-button').click
      wait_for_requests
    end

    it 'allows pinning items from flyout menu with mouse hover and click' do
      # Hover over the Operate section to open flyout
      section_button = find(:button, id: 'menu-section-button-operate')
      section_button.hover

      # Wait for flyout to appear and be fully visible
      flyout = find('#menu-section-button-operate-flyout', visible: :visible)

      # Find and pin an item in the flyout menu
      within flyout do
        nav_item = find_by_testid('nav-item', text: 'Environments')
        nav_item.hover
        find_by_testid('nav-item-pin', context: nav_item).click
        wait_for_requests
      end

      # Verify item is pinned by checking the pinned section flyout
      pinned_button = find(:button, id: 'menu-section-button-pinned')
      pinned_button.hover

      pinned_flyout = find('#menu-section-button-pinned-flyout', visible: :visible)
      within pinned_flyout do
        expect(page).to have_link 'Environments'
      end
    end

    it 'allows unpinning items from pinned section flyout with mouse hover and click' do
      # First, pin an item
      section_button = find(:button, id: 'menu-section-button-operate')
      section_button.hover

      flyout = find('#menu-section-button-operate-flyout', visible: :visible)
      within flyout do
        nav_item = find_by_testid('nav-item', text: 'Environments')
        nav_item.hover
        find_by_testid('nav-item-pin', context: nav_item).click
        wait_for_requests
      end

      # Now unpin it from the pinned section
      pinned_button = find(:button, id: 'menu-section-button-pinned')
      pinned_button.hover

      pinned_flyout = find('#menu-section-button-pinned-flyout', visible: :visible)
      within pinned_flyout do
        nav_item = find_by_testid('nav-item', text: 'Environments')
        nav_item.hover
        find_by_testid('nav-item-unpin', context: nav_item).click
        wait_for_requests
      end

      # Verify item is no longer pinned
      pinned_button.hover
      pinned_flyout = find('#menu-section-button-pinned-flyout', visible: :visible)
      within pinned_flyout do
        expect(page).not_to have_link 'Environments'
      end
    end

    it 'allows unpinning items from their original section flyout with mouse hover and click' do
      # First, pin an item
      section_button = find(:button, id: 'menu-section-button-operate')
      section_button.hover

      flyout = find('#menu-section-button-operate-flyout', visible: :visible)
      within flyout do
        nav_item = find_by_testid('nav-item', text: 'Environments')
        nav_item.hover
        find_by_testid('nav-item-pin', context: nav_item).click
        wait_for_requests
      end

      # Verify it's pinned
      pinned_button = find(:button, id: 'menu-section-button-pinned')
      pinned_button.hover

      pinned_flyout = find('#menu-section-button-pinned-flyout', visible: :visible)
      within pinned_flyout do
        expect(page).to have_link 'Environments'
      end

      # Now unpin it from the original section
      section_button.hover
      flyout = find('#menu-section-button-operate-flyout', visible: :visible)
      within flyout do
        nav_item = find_by_testid('nav-item', text: 'Environments')
        nav_item.hover
        find_by_testid('nav-item-unpin', context: nav_item).click
        wait_for_requests
      end

      # Verify item is no longer pinned
      pinned_button.hover
      pinned_flyout = find('#menu-section-button-pinned-flyout', visible: :visible)
      within pinned_flyout do
        expect(page).not_to have_link 'Environments'
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
        expect(pinned_items).to eq ["Work items", "Merge requests", "Commits", "Members", "Activity"]
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
          click_on 'Work items'
        end
      end

      it 'shows the Pinned section as expanded and the original section as collapsed' do
        within_testid 'pinned-nav-items' do
          expect(page).to have_link 'Work items'
        end

        within '#menu-section-button-plan' do
          expect(page).not_to have_link 'Work items'
        end
      end
    end

    context 'when a pinned item is clicked in its original section' do
      before do
        within '#super-sidebar' do
          click_on 'Plan'
        end
        within '#super-sidebar #plan' do
          click_on 'Work items'
        end
      end

      it 'shows the Pinned section as collapsed and the original section as expanded' do
        within '#menu-section-button-plan' do
          expect(page).not_to have_link 'Work items'
        end
        within '#super-sidebar #plan' do
          expect(page).to have_link 'Work items'
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
