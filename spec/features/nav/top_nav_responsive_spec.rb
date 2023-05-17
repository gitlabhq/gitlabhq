# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'top nav responsive', :js, feature_category: :navigation do
  include MobileHelpers
  include Features::InviteMembersModalHelpers

  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)

    resize_screen_xs
  end

  context 'when outside groups and projects' do
    before do
      visit explore_projects_path
    end

    context 'when menu is closed' do
      it 'has page content and hides responsive menu', :aggregate_failures do
        expect(page).to have_css('.page-title', text: 'Explore projects')
        expect(page).to have_link('Homepage', id: 'logo')

        expect(page).to have_no_css('.top-nav-responsive')
      end
    end

    context 'when menu is opened' do
      before do
        click_button('Menu')
      end

      it 'hides everything and shows responsive menu', :aggregate_failures do
        expect(page).to have_no_css('.page-title', text: 'Explore projects')
        expect(page).to have_no_link('Homepage', id: 'logo')

        within '.top-nav-responsive' do
          expect(page).to have_link(nil, href: search_path)
          expect(page).to have_button('Projects')
          expect(page).to have_button('Groups')
          expect(page).to have_link('Your work', href: dashboard_projects_path)
          expect(page).to have_link('Explore', href: explore_projects_path)
        end
      end

      it 'has new dropdown', :aggregate_failures do
        create_new_button.click

        expect(page).to have_link('New project', href: new_project_path)
        expect(page).to have_link('New group', href: new_group_path)
        expect(page).to have_link('New snippet', href: new_snippet_path)
      end
    end
  end

  context 'when inside a project' do
    let_it_be(:project) { create(:project).tap { |record| record.add_owner(user) } }

    before do
      visit project_path(project)
    end

    it 'the add menu contains invite members dropdown option and opens invite modal' do
      invite_members_from_menu

      page.within invite_modal_selector do
        expect(page).to have_content("You're inviting members to the #{project.name} project")
      end
    end
  end

  context 'when inside a group' do
    let_it_be(:group) { create(:group).tap { |record| record.add_owner(user) } }

    before do
      visit group_path(group)
    end

    it 'the add menu contains invite members dropdown option and opens invite modal' do
      invite_members_from_menu

      page.within invite_modal_selector do
        expect(page).to have_content("You're inviting members to the #{group.name} group")
      end
    end
  end

  def invite_members_from_menu
    click_button('Menu')
    create_new_button.click

    click_button('Invite members')
  end

  def create_new_button
    find('[data-testid="plus-icon"]')
  end
end
