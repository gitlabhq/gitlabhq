# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Usage Quotas > Storage tab', :js, feature_category: :consumables_cost_management do
  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, group: group) }
  let_it_be_with_reload(:statistics) { create(:project_statistics, project: project, repository_size: 12.megabytes) }

  before_all do
    group.add_owner(user)
  end

  before do
    sign_in(user)
  end

  context 'when directly accessed via a url' do
    before do
      visit project_usage_quotas_path(project, anchor: 'storage-quota-tab')
    end

    it 'displays the tab header' do
      within_testid 'storage-tab-app' do
        expect(page).to have_text('Usage breakdown')
      end
    end

    it 'displays the total project storage size' do
      within_testid 'total-usage' do
        expect(page).to have_text('12.0 MiB')
      end
    end
  end
end
