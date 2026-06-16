# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Group pagination', :with_current_organization, feature_category: :groups_and_projects do
  let_it_be(:current_user) { create(:admin) }

  before do
    allow(Kaminari.config).to receive(:default_per_page).and_return(1)
    sign_in(current_user)
    enable_admin_mode!(current_user)
  end

  describe 'projects pagination' do
    let_it_be(:group) { create(:group) }

    before_all do
      create_list(:project, 2, namespace: group)
    end

    it 'shows pagination on the first page' do
      visit admin_group_path(group)

      expect(page).to have_css('.gl-pagination')
    end

    it 'shows pagination on the last page' do
      visit admin_group_path(group, projects_page: 2)

      expect(page).to have_css('.gl-pagination')
    end
  end

  describe 'members pagination' do
    let_it_be(:group) { create(:group) }

    before_all do
      create_list(:user, 2).each do |u|
        group.add_developer(u)
      end
    end

    it 'shows pagination on the first page' do
      visit admin_group_path(group)

      expect(page).to have_css('.gl-pagination')
    end

    it 'shows pagination on the last page' do
      visit admin_group_path(group, members_page: 2)

      expect(page).to have_css('.gl-pagination')
    end
  end
end
