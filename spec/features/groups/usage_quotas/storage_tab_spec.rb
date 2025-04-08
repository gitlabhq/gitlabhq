# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Usage Quotas > Storage tab', :js, feature_category: :consumables_cost_management do
  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:root_storage_statistics) do
    create(:namespace_root_storage_statistics, namespace: group, storage_size: 12.megabytes)
  end

  before_all do
    group.add_owner(user)
  end

  before do
    # Disable the logic that reaches out to CDot
    stub_feature_flags(limited_access_modal: false)
    stub_application_setting(check_namespace_plan: false)
    sign_in(user)
  end

  it_behaves_like 'namespace Usage Quotas > Storage tab' do
    let_it_be(:namespace_storage_size_used_text) { '12.0 MiB' }
    let_it_be(:storage_tab_url) { group_usage_quotas_path(group, anchor: 'storage-quota-tab') }
  end
end
