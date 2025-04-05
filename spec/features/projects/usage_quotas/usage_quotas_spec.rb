# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Usage Quotas', :js, feature_category: :consumables_cost_management do
  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, group: group) }

  before_all do
    group.add_owner(user)
  end

  before do
    sign_in(user)
  end

  it_behaves_like 'Usage Quotas is accessible' do
    let(:usage_quotas_path) { project_usage_quotas_path(project) }

    before do
      visit edit_project_path(project)
    end
  end
end
