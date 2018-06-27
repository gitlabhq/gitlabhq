require 'spec_helper'

describe 'User find project file' do
  let(:user)    { create :user }
  let(:project) { create :project, :repository }

  before do
    sign_in(user)
    project.add_master(user)

    visit project_tree_path(project, project.repository.root_ref)
  end

  def active_main_tab
    find('.sidebar-top-level-items > li.active')
  end

  def find_file(text)
    fill_in 'file_find', with: text
  end

  it 'navigates to find file by shortcut', :js do
    find('body').native.send_key('t')

    expect(active_main_tab).to have_content('Repository')
    expect(page).to have_selector('.file-finder-holder', count: 1)
  end

  it 'navigates to find file' do
    click_link 'Find file'

    expect(active_main_tab).to have_content('Repository')
    expect(page).to have_selector('.file-finder-holder', count: 1)
  end

  it 'searches CHANGELOG file', :js do
    click_link 'Find file'

    find_file 'change'

    expect(page).to have_content('CHANGELOG')
    expect(page).not_to have_content('.gitignore')
    expect(page).not_to have_content('VERSION')
  end

  it 'does not find file when search not exist file', :js do
    click_link 'Find file'

    find_file 'asdfghjklqwertyuizxcvbnm'

    expect(page).not_to have_content('CHANGELOG')
    expect(page).not_to have_content('.gitignore')
    expect(page).not_to have_content('VERSION')
  end

  it 'searches file by partially matches', :js do
    click_link 'Find file'

    find_file 'git'

    expect(page).to have_content('.gitignore')
    expect(page).to have_content('.gitmodules')
    expect(page).not_to have_content('CHANGELOG')
    expect(page).not_to have_content('VERSION')
  end
end
