# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group variables', :js, feature_category: :ci_variables do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let!(:variable) { create(:ci_group_variable, key: 'test_key', value: 'test_value', masked: true, group: group) }
  let(:page_path) { group_settings_ci_cd_path(group) }

  before do
    group.add_owner(user)
    gitlab_sign_in(user)

    visit page_path
    wait_for_requests
  end

  context 'when ci_variables_pages FF is enabled' do
    it_behaves_like 'variable list drawer'
    it_behaves_like 'variable list env scope'
    it_behaves_like 'variable list pagination', :ci_group_variable
  end

  context 'when ci_variables_pages FF is disabled' do
    before do
      stub_feature_flags(ci_variables_pages: false)
    end

    it_behaves_like 'variable list drawer'
    it_behaves_like 'variable list env scope'
  end
end
