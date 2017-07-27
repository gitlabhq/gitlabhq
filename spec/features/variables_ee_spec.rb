require 'spec_helper'

describe 'Project variables EE', js: true do
  let(:user)     { create(:user) }
  let(:project)  { create(:empty_project) }
  let(:variable) { create(:ci_variable, key: 'test_key', value: 'test value') }

  let(:variable_environment_scope) { true }

  before do
    stub_licensed_features(
      variable_environment_scope: variable_environment_scope)

    login_as(user)
    project.team << [user, :master]
    project.variables << variable

    visit project_settings_ci_cd_path(project)
  end

  it 'adds new variable with a special environment scope' do
    expect(page).to have_selector('#variable_environment_scope')

    fill_in('variable_key', with: 'key')
    fill_in('variable_value', with: 'value')
    fill_in('variable_environment_scope', with: 'review/*')
    click_button('Add new variable')

    expect(page).to have_content('Variable was successfully created.')
    page.within('.variables-table') do
      expect(page).to have_content('key')
      expect(page).to have_content('review/*')
    end
  end

  context 'when variable environment scope is not available' do
    let(:variable_environment_scope) { false }

    it 'does not show variable environment scope element' do
      expect(page).not_to have_selector('#variable_environment_scope')
    end
  end

  context 'when editing a variable for environment' do
    before do
      page.within('.variables-table') do
        find('.btn-variable-edit').click
      end
    end

    it 'edits variable to be another environment scope' do
      expect(page).to have_selector('#variable_environment_scope')

      fill_in('variable_environment_scope', with: 'review/*')
      click_button('Save variable')

      expect(page).to have_content('Variable was successfully updated.')
      expect(project.variables(true).first.environment_scope).to eq('review/*')
    end

    context 'when variable environment scope is not available' do
      let(:variable_environment_scope) { false }

      it 'does not show environment scope element' do
        expect(page).not_to have_selector('#variable_environment_scope')
      end
    end
  end
end
