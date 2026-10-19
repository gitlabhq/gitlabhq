# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Packages', feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    sign_in(user)
    group.add_maintainer(user)
  end

  context 'when feature is not available' do
    context 'packages feature is disabled by config' do
      before do
        allow(Gitlab.config.packages).to receive(:enabled).and_return(false)
      end

      it 'gives 404' do
        visit_group_packages

        expect(page).to have_gitlab_http_status(:not_found)
      end
    end
  end

  context 'when feature is available', :js do
    before do
      visit_group_packages
    end

    it 'sidebar menu is open' do
      sidebar = find_by_testid('super-sidebar')
      expect(sidebar).to have_link _('Package registry')
    end
  end

  def visit_group_packages
    visit group_packages_path(group)
  end
end
