require 'spec_helper'

describe 'Project variables', js: true do
  let(:user)     { create(:user) }
  let(:project)  { create(:empty_project) }
  let(:variable) { create(:ci_variable, key: 'test_key', value: 'test value') }

  before do
    sign_in(user)
    project.team << [user, :master]
    project.variables << variable

    visit project_settings_ci_cd_path(project)
  end

  it 'shows list of variables' do
    page.within('.variables-table') do
      expect(page).to have_content(variable.key)
    end
  end

  it 'adds new secret variable' do
    fill_in('variable_key', with: 'key')
    fill_in('variable_value', with: 'key value')
    click_button('Add new variable')

    expect(page).to have_content('Variable was successfully created.')
    page.within('.variables-table') do
      expect(page).to have_content('key')
      expect(page).to have_content('No')
    end
  end

  it 'adds empty variable' do
    fill_in('variable_key', with: 'new_key')
    fill_in('variable_value', with: '')
    click_button('Add new variable')

    expect(page).to have_content('Variable was successfully created.')
    page.within('.variables-table') do
      expect(page).to have_content('new_key')
    end
  end

  it 'adds new protected variable' do
    fill_in('variable_key', with: 'key')
    fill_in('variable_value', with: 'value')
    check('Protected')
    click_button('Add new variable')

    expect(page).to have_content('Variable was successfully created.')
    page.within('.variables-table') do
      expect(page).to have_content('key')
      expect(page).to have_content('Yes')
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
      click_on 'Remove'
    end

    expect(page).not_to have_selector('variables-table')
  end

  it 'edits variable' do
    page.within('.variables-table') do
      click_on 'Update'
    end

    expect(page).to have_content('Update variable')
    fill_in('variable_key', with: 'key')
    fill_in('variable_value', with: 'key value')
    click_button('Save variable')

    expect(page).to have_content('Variable was successfully updated.')
    expect(project.variables(true).first.value).to eq('key value')
  end

  it 'edits variable with empty value' do
    page.within('.variables-table') do
      click_on 'Update'
    end

    expect(page).to have_content('Update variable')
    fill_in('variable_value', with: '')
    click_button('Save variable')

    expect(page).to have_content('Variable was successfully updated.')
    expect(project.variables(true).first.value).to eq('')
  end

  it 'edits variable to be protected' do
    page.within('.variables-table') do
      click_on 'Update'
    end

    expect(page).to have_content('Update variable')
    check('Protected')
    click_button('Save variable')

    expect(page).to have_content('Variable was successfully updated.')
    expect(project.variables(true).first).to be_protected
  end

  it 'edits variable to be unprotected' do
    project.variables.first.update(protected: true)

    page.within('.variables-table') do
      click_on 'Update'
    end

    expect(page).to have_content('Update variable')
    uncheck('Protected')
    click_button('Save variable')

    expect(page).to have_content('Variable was successfully updated.')
    expect(project.variables(true).first).not_to be_protected
  end
end
