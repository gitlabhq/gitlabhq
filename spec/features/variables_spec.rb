require 'spec_helper'

describe 'Project variables', js: true do
  let(:user)     { create(:user) }
  let(:project)  { create(:project) }
  let(:variable) { create(:ci_variable, key: 'test_key', value: 'test value') }

  before do
    login_as(user)
    project.team << [user, :master]
    project.variables << variable

    visit namespace_project_settings_ci_cd_path(project.namespace, project)
  end

  it 'shows list of variables' do
    page.within('.variables-table') do
      expect(page).to have_content(variable.key)
    end
  end

  it 'adds new variable' do
    fill_in('variable_key', with: 'key')
    fill_in('variable_value', with: 'key value')
    click_button('Add new variable')

    expect(page).to have_content('Variables were successfully updated.')
    page.within('.variables-table') do
      expect(page).to have_content('key')
    end
  end

  it 'adds empty variable' do
    fill_in('variable_key', with: 'new_key')
    fill_in('variable_value', with: '')
    click_button('Add new variable')

    expect(page).to have_content('Variables were successfully updated.')
    page.within('.variables-table') do
      expect(page).to have_content('new_key')
    end
  end

  it 'reveals and hides new variable' do
    fill_in('variable_key', with: 'key')
    fill_in('variable_value', with: 'key value')
    click_button('Add new variable')

    page.within('.variables-table') do
      expect(page).to have_content('key')
      expect(page).to have_content('******')
    end

    click_button('Reveal Values')

    page.within('.variables-table') do
      expect(page).to have_content('key')
      expect(page).to have_content('key value')
    end

    click_button('Hide Values')

    page.within('.variables-table') do
      expect(page).to have_content('key')
      expect(page).to have_content('******')
    end
  end

  it 'deletes variable' do
    page.within('.variables-table') do
      find('.btn-variable-delete').click
    end

    expect(page).not_to have_selector('variables-table')
  end

  it 'edits variable' do
    page.within('.variables-table') do
      find('.btn-variable-edit').click
    end

    expect(page).to have_content('Update variable')
    fill_in('variable_key', with: 'key')
    fill_in('variable_value', with: 'key value')
    click_button('Save variable')

    expect(page).to have_content('Variable was successfully updated.')
    expect(project.variables.first.value).to eq('key value')
  end

  it 'edits variable with empty value' do
    page.within('.variables-table') do
      find('.btn-variable-edit').click
    end

    expect(page).to have_content('Update variable')
    fill_in('variable_value', with: '')
    click_button('Save variable')

    expect(page).to have_content('Variable was successfully updated.')
    expect(project.variables.first.value).to eq('')
  end
end
