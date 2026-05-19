# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Subgroup service accounts', :js, feature_category: :user_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:user) { create(:user) }

  before_all do
    group.add_owner(user)
  end

  before do
    stub_application_setting(allow_top_level_group_owners_to_create_service_accounts: true)
    sign_in(user)
  end

  it_behaves_like 'service account CRUD', path_helper_method: :group_settings_service_accounts_path do
    let_it_be(:resource) { subgroup }
    let_it_be(:provisioning_attribute) { { provisioned_by_group: subgroup } }
  end
end
