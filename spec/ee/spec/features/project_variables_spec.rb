require 'spec_helper'

describe 'Project variables EE', :js do
  let(:user)     { create(:user) }
  let(:project)  { create(:project) }
  let(:variable) { create(:ci_variable, key: 'test_key', value: 'test value') }
  let(:page_path) { project_settings_ci_cd_path(project) }

  before do
    stub_licensed_features(variable_environment_scope: variable_environment_scope)

    login_as(user)
    project.add_master(user)
    project.variables << variable

    visit page_path
  end

  context 'when variable environment scope is available' do
    let(:variable_environment_scope) { true }

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

      page.within('.js-ci-variable-list-section .js-row:nth-child(1)') do
        expect(find('.js-ci-variable-input-key').value).to eq('somekey')
        expect(page).to have_content('review/*')
      end
    end
  end

  context 'when variable environment scope is not available' do
    let(:variable_environment_scope) { false }

    it 'does not show variable environment scope element' do
      expect(page).not_to have_selector('input[name="variables[variables_attributes][][environment_scope]"]')
      expect(page).not_to have_selector('.js-variable-environment-dropdown-wrapper')
    end
  end
end
