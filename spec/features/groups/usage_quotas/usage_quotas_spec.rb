# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Usage Quotas', :js, feature_category: :consumables_cost_management do
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:sub_group) { create(:group, parent: group) }

  before_all do
    group.add_owner(user)
  end

  before do
    # Disable the logic that reaches out to CDot
    stub_feature_flags(limited_access_modal: false)
    sign_in(user)
  end

  it_behaves_like 'Usage Quotas is accessible' do
    let(:usage_quotas_path) { group_usage_quotas_path(group) }

    before do
      visit edit_group_path(group)
    end
  end

  context 'when in a subgroup' do
    it 'is not linked from the sidebar in a subgroup' do
      visit edit_group_path(sub_group)

      within_testid('super-sidebar') do
        expect(page).not_to have_link('Usage Quotas')
      end
    end

    it 'does not show the subgroup' do
      visit group_usage_quotas_path(sub_group)

      expect(page).to have_title('Not Found')
    end
  end
end
