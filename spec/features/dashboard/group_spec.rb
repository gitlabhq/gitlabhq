# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard Group', :with_current_organization, :js, feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    current_organization.users << user
  end

  context 'when user has no groups' do
    before do
      sign_in(user)
    end

    it 'renders empty state' do
      visit dashboard_groups_path

      expect(page).to have_css '[data-testid="groups-empty-state"]'
    end

    context 'and cannot create groups' do
      let(:user) { create(:user, can_create_group: false) }

      it 'does not render New Group button' do
        visit dashboard_groups_path
        expect(page).not_to have_css '[data-testid="new-group-button"]'
      end
    end

    context 'and can create groups' do
      let(:user) { create(:user, can_create_group: true) }

      it 'renders New Group button' do
        visit dashboard_groups_path
        expect(page).to have_css '[data-testid="new-group-button"]'
      end

      it 'creates new group' do
        visit dashboard_groups_path
        find_by_testid('new-group-button').click
        click_link 'Create group'

        new_name = 'Samurai'

        fill_in 'group_name', with: new_name
        click_button 'Create group'

        expect(page).to have_current_path group_path(Group.find_by(name: new_name)), ignore_query: true
        expect(page).to have_content(new_name)
      end
    end
  end

  context 'when user has groups' do
    before do
      sign_in(user)
      group.add_developer(user)
    end

    it 'defaults sort dropdown to Created date' do
      visit dashboard_groups_path

      expect(page).to have_button('Created date')
    end
  end
end
