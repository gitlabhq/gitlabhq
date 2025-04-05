# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Usage Quota', :js, feature_category: :consumables_cost_management do
  let_it_be_with_reload(:user) { create(:user, :with_namespace) }
  let_it_be_with_reload(:namespace) { user.namespace }

  before do
    sign_in(user)
  end

  it_behaves_like 'Usage Quotas is accessible' do
    let(:usage_quotas_path) { profile_usage_quotas_path }

    before do
      visit user_settings_profile_path
    end
  end
end
