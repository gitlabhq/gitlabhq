require 'spec_helper'

describe 'Project variables', js: true do
  let(:user)     { create(:user) }
  let(:project)  { create(:project) }
  let(:variable) { create(:ci_variable, key: 'test') }

  before do
    login_as(user)
    project.team << [user, :master]
    project.variables << variable

    visit namespace_project_variables_path(project.namespace, project)
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

    page.within('.variables-table') do
      expect(page).to have_content('key')
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

    page.within('.variables-table') do
      expect(page).to have_content('key')
    end
  end
end
