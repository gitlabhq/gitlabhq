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

  it 'adds new variable with a special environment scope' do
    page.within('.js-ci-variable-list-section .js-row:last-child') do
      find('.js-ci-variable-input-key').set('somekey')
      find('.js-ci-variable-input-value').set('somevalue')

      find('.js-variable-environment-toggle').click
      find('.js-variable-environment-dropdown-wrapper .dropdown-input-field').set('review/*')
      find('.js-variable-environment-dropdown-wrapper .js-dropdown-create-new-item').click

      expect(find('input[name="variables[variables_attributes][][environment_scope]"]', visible: false).value).to eq('review/*')
    end

    click_button('Save variables')
    wait_for_requests

    visit page_path

    page.within('.js-ci-variable-list-section .js-row:nth-child(2)') do
      expect(find('.js-ci-variable-input-key').value).to eq('somekey')
      expect(page).to have_content('review/*')
    end
  end
end
