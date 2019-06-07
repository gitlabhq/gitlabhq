# frozen_string_literal: true

require 'spec_helper'

describe 'Project variables', :js do
  let(:user)     { create(:user) }
  let(:project)  { create(:project) }
  let(:variable) { create(:ci_variable, key: 'test_key', value: 'test_value', masked: true) }
  let(:page_path) { project_settings_ci_cd_path(project) }

  before do
    sign_in(user)
    project.add_maintainer(user)
    project.variables << variable

    visit page_path
  end

  it_behaves_like 'variable list'
end
