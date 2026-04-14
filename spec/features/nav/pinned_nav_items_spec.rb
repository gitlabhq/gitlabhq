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
      # --- Pin Activity and Members via keyboard ---
      # Open the Manage section with Enter and wait for aria-expanded to confirm
      # the collapse panel is open before tabbing into its items. Without this
      # guard the GlCollapse transition may still be running when the first :tab
      # fires, causing focus to land outside the section entirely.
      manage_button = find(:button, id: 'menu-section-button-manage')
      manage_button.base.send_keys(:enter)
      expect(manage_button['aria-expanded']).to eq('true')

      # Manage section item order: Activity, Members, Labels.
      # Tab 1: Activity nav link, Tab 2: Activity pin button.
      manage_button.base.send_keys(:tab, :tab)
      expect(page.find(':focus')['aria-label']).to eq('Pin Activity')
      page.find(':focus').send_keys(:enter)
      wait_for_requests

      # Tab 1: Members nav link, Tab 2: Members pin button.
      page.find(':focus').send_keys(:tab, :tab)
      expect(page.find(':focus')['aria-label']).to eq('Pin Members')
      page.find(':focus').send_keys(:enter)
      wait_for_requests

      within_testid 'pinned-nav-items' do
        expect(page).to have_link 'Work items'
        expect(page).to have_link 'Activity'
        expect(page).to have_link 'Members'
      end

      # --- Unpin Work items and Activity via keyboard ---
      # Explicitly focus the Pinned section button.
      # Pinned section item order: Work items, Activity, Members.
      # Tab 1: Work items nav link, Tab 2: Work items unpin button.
      pinned_button = find(:button, id: 'menu-section-button-pinned')
      expect(pinned_button['aria-expanded']).to eq('true')

      pinned_button.base.send_keys(:tab, :tab)
      expect(page.find(':focus')['aria-label']).to eq('Unpin Work items')
      page.find(':focus').send_keys(:space)
      wait_for_requests

      # Tab 1: Activity nav link, Tab 2: Activity unpin button.
      page.find(':focus').send_keys(:tab, :tab)
      expect(page.find(':focus')['aria-label']).to eq('Unpin Activity')
      page.find(':focus').send_keys(:space)
      wait_for_requests

      within_testid 'pinned-nav-items' do
        expect(page).not_to have_link 'Work items'
        expect(page).not_to have_link 'Activity'
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
      manage_button = find(:button, id: 'menu-section-button-manage')
      manage_button.base.send_keys(:enter)
      expect(page).to have_css('#menu-section-button-manage-flyout', visible: :visible)

      send_keys(:escape)
      expect(page).not_to have_css('#menu-section-button-manage-flyout', visible: :visible)
    end

    it 'opens and closes flyout menu with Space key' do
      manage_button = find(:button, id: 'menu-section-button-manage')
      manage_button.base.send_keys(:space)
      expect(page).to have_css('#menu-section-button-manage-flyout', visible: :visible)

      send_keys(:escape)
      expect(page).not_to have_css('#menu-section-button-manage-flyout', visible: :visible)
    end

    it 'returns focus to section button after closing flyout with Escape' do
      manage_button = find(:button, id: 'menu-section-button-manage')
      manage_button.base.send_keys(:enter)
      expect(page).to have_css('#menu-section-button-manage-flyout', visible: :visible)

      send_keys(:tab)
      send_keys(:escape)
      expect(page).not_to have_css('#menu-section-button-manage-flyout', visible: :visible)
      expect(page.find(':focus')).to eq(manage_button)
    end

    it 'pins item from flyout menu using Enter key' do
      pin_item_via_keyboard('operate', 'Environments')

      # Open the Pinned flyout and verify Environments was pinned.
      open_flyout_via_keyboard('pinned')

      within '#menu-section-button-pinned-flyout' do
        expect(page).to have_link 'Environments'
      end
    end

    it 'removes pinned item from pinned section using Space key' do
      # --- Setup: pin Environments via keyboard ---
      pin_item_via_keyboard('operate', 'Environments')

      # --- Verify Environments is pinned ---
      open_flyout_via_keyboard('pinned')

      within '#menu-section-button-pinned-flyout' do
        expect(page).to have_link 'Environments'
      end

      # --- Unpin Environments from the pinned flyout via keyboard ---
      # The flyout is still open. Pinned flyout item order: Work items, Environments.
      # Tab 1: Work items nav link, Tab 2: Work items unpin button,
      # Tab 3: Environments nav link, Tab 4: Environments unpin button.
      pinned_button = find(:button, id: 'menu-section-button-pinned')
      pinned_button.base.send_keys(:tab, :tab, :tab, :tab)
      expect(page.find(':focus')['aria-label']).to eq('Unpin Environments')
      page.find(':focus').send_keys(:space)
      wait_for_requests

      within '#menu-section-button-pinned-flyout' do
        expect(page).not_to have_link 'Environments'
        expect(page).to have_link 'Work items'
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
      pin_item_via_flyout('operate', 'Environments')

      # Verify item is pinned by checking the pinned section flyout
      open_flyout_via_hover('pinned')

      within '#menu-section-button-pinned-flyout' do
        expect(page).to have_link 'Environments'
      end
    end

    it 'allows unpinning items from pinned section flyout with mouse hover and click' do
      pin_item_via_flyout('operate', 'Environments')

      # Unpin from the pinned section flyout
      open_flyout_via_hover('pinned')

      within '#menu-section-button-pinned-flyout' do
        nav_item = find_by_testid('nav-item', text: 'Environments')
        native_hover(nav_item)
        find_by_testid('nav-item-unpin', context: nav_item).click
        wait_for_requests
      end

      dismiss_flyout('pinned')

      # Verify item is no longer pinned
      open_flyout_via_hover('pinned')

      within '#menu-section-button-pinned-flyout' do
        expect(page).not_to have_link 'Environments'
      end
    end

    it 'allows unpinning items from their original section flyout with mouse hover and click' do
      pin_item_via_flyout('operate', 'Environments')

      # Verify it's pinned
      open_flyout_via_hover('pinned')

      within '#menu-section-button-pinned-flyout' do
        expect(page).to have_link 'Environments'
      end

      dismiss_flyout('pinned')

      # Unpin from the original Operate section flyout
      open_flyout_via_hover('operate')

      within '#menu-section-button-operate-flyout' do
        nav_item = find_by_testid('nav-item', text: 'Environments')
        native_hover(nav_item)
        find_by_testid('nav-item-unpin', context: nav_item).click
        wait_for_requests
      end

      dismiss_flyout('operate')

      # Verify item is no longer pinned
      open_flyout_via_hover('pinned')

      within '#menu-section-button-pinned-flyout' do
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

  # Uses native Selenium WebDriver actions to move the mouse pointer to the
  # center of the given element. Unlike Capybara's `.hover`, which synthesizes
  # a single moveToElement call, this builds an explicit action chain that
  # produces reliable pointerleave/pointerover events in headless Chrome.
  #
  # Capybara's `.hover` is unreliable for flyout tests because:
  # 1. If the cursor is already over the target, headless Chrome may skip the
  #    pointerover event entirely (no boundary crossing detected).
  # 2. Rapid sequential `.hover` calls can race with the 5ms setTimeout in
  #    menu_section.vue's handlePointerleave, causing the delayed
  #    isMouseOverSection=false to fire *after* the next pointerover.
  def native_hover(element)
    page.driver.browser.action.move_to(element.native).perform
  end

  # Moves the mouse to the sidebar logo (a neutral, non-section element) via
  # native WebDriver actions to guarantee a pointerleave fires on the current
  # section button. This resets isMouseOverSection in menu_section.vue so the
  # next hover reliably triggers pointerover and re-opens the flyout.
  #
  # The $nextTick mouseleave emitted by flyout_menu.vue after pin/unpin actions
  # (a Safari fix) only clears isMouseOverFlyout, leaving isMouseOverSection
  # stale at true. Without physically moving the pointer away, a subsequent
  # hover on the same button is a no-op.
  def move_mouse_to_neutral_element
    native_hover(find_by_testid('brand-header-default-logo'))
  end

  # Dismisses a flyout by moving the mouse to a neutral element and waiting for
  # the flyout to fully close. This guarantees the component's internal state
  # (isMouseOverSection, isMouseOverFlyout, keepFlyoutClosed) has settled before
  # the next interaction.
  def dismiss_flyout(section_id)
    move_mouse_to_neutral_element
    expect(page).not_to have_css("#menu-section-button-#{section_id}-flyout", visible: :visible)
  end

  # Opens a collapsed-sidebar flyout via native mouse hover. Moves to a neutral
  # element first to ensure a clean pointerleave/pointerover cycle, then pauses
  # briefly to let the 5ms handlePointerleave setTimeout in menu_section.vue
  # resolve before the pointerover fires on the target button.
  def open_flyout_via_hover(section_id)
    target = find(:button, id: "menu-section-button-#{section_id}")
    neutral = find_by_testid('brand-header-default-logo')

    # Single atomic action chain: move away then pause for pointerleave setTimeout
    # (5ms in menu_section.vue) plus Vue's reactivity cycle to resolve then move
    # to target. 100ms provides comfortable margin over the 5ms setTimeout.
    page.driver.browser.action
      .move_to(neutral.native)
      .pause(duration: 0.1)
      .move_to(target.native)
      .perform

    expect(page).to have_css("#menu-section-button-#{section_id}-flyout", visible: :visible)
  end

  # Pins an item from a collapsed-sidebar flyout using the mouse, then dismisses
  # the flyout so subsequent interactions start from a clean state.
  def pin_item_via_flyout(section_id, item_title)
    open_flyout_via_hover(section_id)

    within "#menu-section-button-#{section_id}-flyout" do
      nav_item = find_by_testid('nav-item', text: item_title)
      native_hover(nav_item)
      find_by_testid('nav-item-pin', context: nav_item).click
      wait_for_requests
    end

    # After a pin action, flyout_menu.vue emits a mouseleave via $nextTick to
    # close the flyout (Safari fix). Wait for it to fully unmount before any
    # further interaction.
    dismiss_flyout(section_id)
  end

  # Opens a collapsed-sidebar flyout via keyboard (Enter), with an Escape to
  # close any previously open flyout first. In icon-only mode, Enter toggles
  # isMouseOverSection which renders the flyout.
  def open_flyout_via_keyboard(section_id)
    button = find(:button, id: "menu-section-button-#{section_id}")
    button.base.send_keys(:enter)
    expect(page).to have_css("#menu-section-button-#{section_id}-flyout", visible: :visible)
  end

  # Pins an item from a collapsed-sidebar flyout using the keyboard, then
  # closes the flyout with Escape so subsequent interactions start clean.
  def pin_item_via_keyboard(section_id, item_title)
    open_flyout_via_keyboard(section_id)

    button = find(:button, id: "menu-section-button-#{section_id}")
    # Tab into the flyout: Tab 1 = nav link, Tab 2 = pin button for first item.
    button.base.send_keys(:tab, :tab)
    expect(page.find(':focus')['aria-label']).to eq("Pin #{item_title}")
    page.find(':focus').send_keys(:enter)
    wait_for_requests

    # Escape closes the flyout and returns focus to the section button.
    page.find(':focus').send_keys(:escape)
    expect(page).not_to have_css("#menu-section-button-#{section_id}-flyout", visible: :visible)
  end
end
