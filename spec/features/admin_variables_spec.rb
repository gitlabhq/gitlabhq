# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Instance variables', :js do
  let(:admin) { create(:admin) }
  let(:page_path) { ci_cd_admin_application_settings_path }

  let_it_be(:variable) { create(:ci_instance_variable, key: 'test_key', value: 'test_value', masked: true) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
    wait_for_requests
  end

  context 'with disabled ff `ci_variable_settings_graphql' do
    before do
      stub_feature_flags(ci_variable_settings_graphql: false)
      visit page_path
    end

    it_behaves_like 'variable list', isAdmin: true
  end

  context 'with enabled ff `ci_variable_settings_graphql' do
    before do
      visit page_path
    end

    it_behaves_like 'variable list', isAdmin: true
  end
end
