# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Navigation menu item pinning', :js, feature_category: :navigation do
  let_it_be(:user) { create(:user, use_new_navigation: true) }

  before do
    sign_in(user)
  end

  describe 'non-pinnable navigation menu' do
    before do
      visit explore_projects_path
    end

    it 'does not show the Pinned section' do
      within '#super-sidebar' do
        expect(page).not_to have_content 'Pinned'
      end
    end

    it 'does not show the buttons to pin items' do
      within '#super-sidebar' do
        expect(page).not_to have_css 'button svg[data-testid="thumbtack-icon"]'
      end
    end
  end

  describe 'pinnable navigation menu' do
    let_it_be(:project) { create(:project) }

    before do
      project.add_member(user, :owner)
      visit project_path(project)
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

      within '[data-testid="pinned-nav-items"]' do
        expect(page).to have_link 'Activity'
        expect(page).to have_link 'Members'
      end
    end

    describe 'collapsible section' do
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
          add_pin('Package Registry')
          add_pin('Terraform modules')
          wait_for_requests
        end
      end

      it 'can be unpinned from within the pinned section' do
        within '[data-testid="pinned-nav-items"]' do
          remove_pin('Package Registry')
          expect(page).not_to have_content 'Package Registry'
        end
      end

      it 'can be unpinned from within its section' do
        section = find("button", text: 'Operate')

        within(section.sibling('div')) do
          remove_pin('Terraform modules')
        end

        within '[data-testid="pinned-nav-items"]' do
          expect(page).not_to have_content 'Terraform modules'
        end
      end

      it 'can be reordered' do
        within '[data-testid="pinned-nav-items"]' do
          pinned_items = page.find_all('a').map(&:text)
          item1 = page.find('a', text: 'Package Registry')
          item2 = page.find('a', text: 'Terraform modules')
          expect(pinned_items).to eq [item1.text, item2.text]

          drag_item(item2, to: item1)

          pinned_items = page.find_all('a').map(&:text)
          expect(pinned_items).to eq [item2.text, item1.text]
        end
      end
    end
  end

  describe 'reordering pins with hidden pins from non-available features' do
    let_it_be(:project_with_repo) { create(:project, :repository) }
    let_it_be(:project_without_repo) { create(:project, :repository_disabled) }

    before do
      project_with_repo.add_member(user, :owner)
      project_without_repo.add_member(user, :owner)

      visit project_path(project_with_repo)
      within '#super-sidebar' do
        click_on 'Code'
        add_pin('Commits')
        click_on 'Manage'
        add_pin('Activity')
        add_pin('Members')
      end

      visit project_path(project_without_repo)
      within '[data-testid="pinned-nav-items"]' do
        activity_item = page.find('a', text: 'Activity')
        members_item = page.find('a', text: 'Members')
        drag_item(members_item, to: activity_item)
      end

      visit project_path(project_with_repo)
    end

    it 'keeps pins of non-available features' do
      within '[data-testid="pinned-nav-items"]' do
        pinned_items = page.find_all('a').map(&:text)
        expect(pinned_items).to eq %w[Commits Members Activity]
      end
    end
  end

  private

  def add_pin(menu_item_title)
    menu_item = find("[data-testid=\"nav-item-link\"]", text: menu_item_title)
    menu_item.hover
    menu_item.find("[data-testid=\"thumbtack-icon\"]").click
    wait_for_requests
  end

  def remove_pin(menu_item_title)
    menu_item = find("[data-testid=\"nav-item-link\"]", text: menu_item_title)
    menu_item.hover
    menu_item.find("[data-testid=\"thumbtack-solid-icon\"]").click
    wait_for_requests
  end

  def drag_item(item, to:)
    item.hover
    drag_handle = item.find('[data-testid="grip-icon"]')

    # Reduce delay to make it less likely for draggables to
    # change position during drag operation, which reduces
    # flakiness.
    drag_handle.drag_to(to, delay: 0.01)
    wait_for_requests
  end
end
