# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Instance variables', :js, feature_category: :pipeline_authoring do
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

  it_behaves_like 'variable list', isAdmin: true
end
