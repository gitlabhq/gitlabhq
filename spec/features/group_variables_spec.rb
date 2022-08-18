# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group variables', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let!(:variable) { create(:ci_group_variable, key: 'test_key', value: 'test_value', masked: true, group: group) }
  let(:page_path) { group_settings_ci_cd_path(group) }

  before do
    group.add_owner(user)
    gitlab_sign_in(user)
    wait_for_requests
  end

  context 'with disabled ff `ci_variable_settings_graphql' do
    before do
      stub_feature_flags(ci_variable_settings_graphql: false)
      visit page_path
    end

    it_behaves_like 'variable list'
  end

  context 'with enabled ff `ci_variable_settings_graphql' do
    before do
      visit page_path
    end

    it_behaves_like 'variable list'
  end
end
