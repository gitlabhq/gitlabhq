# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Instance variables', :js, feature_category: :secrets_management do
  let(:admin) { create(:admin) }
  let(:page_path) { ci_cd_admin_application_settings_path }

  let_it_be(:variable) { create(:ci_instance_variable, key: 'test_key', value: 'test_value', masked: true) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)

    visit page_path
    wait_for_requests
  end

  context 'when ci_variables_pages FF is enabled' do
    it_behaves_like 'variable list', is_admin: true
    it_behaves_like 'variable list pagination', :ci_instance_variable
  end

  context 'when ci_variables_pages FF is disabled' do
    before do
      stub_feature_flags(ci_variables_pages: false)
    end

    it_behaves_like 'variable list', is_admin: true
  end
end
