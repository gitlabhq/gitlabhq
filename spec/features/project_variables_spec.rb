# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project variables', :js, feature_category: :ci_variables do
  let(:user)     { create(:user) }
  let(:project)  { create(:project) }
  let(:variable) { create(:ci_variable, key: 'test_key', value: 'test_value', masked: true) }
  let(:page_path) { project_settings_ci_cd_path(project) }

  before do
    sign_in(user)
    project.add_maintainer(user)
    project.variables << variable

    visit page_path
    wait_for_requests
  end

  context 'when ci_variables_pages FF is enabled' do
    it_behaves_like 'variable list drawer'
    it_behaves_like 'variable list env scope'
    it_behaves_like 'variable list pagination', :ci_variable
  end

  context 'when ci_variables_pages FF is disabled' do
    before do
      stub_feature_flags(ci_variables_pages: false)
    end

    it_behaves_like 'variable list drawer'
    it_behaves_like 'variable list env scope'
  end
end
