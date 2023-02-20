# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User find project file', feature_category: :projects do
  include ListboxHelpers

  let(:user)    { create :user }
  let(:project) { create :project, :repository }

  before do
    sign_in(user)
    project.add_maintainer(user)

    visit project_tree_path(project, project.repository.root_ref)
  end

  def active_main_tab
    find('.sidebar-top-level-items > li.active')
  end

  def find_file(text)
    fill_in 'file_find', with: text
  end

  def ref_selector_dropdown
    find('.gl-button-text')
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

  context 'when refs are switched', :js do
    before do
      click_link 'Find file'
    end

    specify 'the ref switcher lists all the branches and tags' do
      ref = 'add-ipython-files'
      expect(ref_selector_dropdown).not_to have_text(ref)

      find('.ref-selector').click
      wait_for_requests

      page.within('.ref-selector') do
        expect(page).to have_selector('li', text: ref)
        expect(page).to have_selector('li', text: 'v1.0.0')
      end
    end

    specify 'the search result changes when refs switched' do
      ref = 'add-ipython-files'
      expect(ref_selector_dropdown).not_to have_text(ref)

      find('.ref-selector button').click
      wait_for_requests

      page.within('.ref-selector') do
        fill_in _('Switch branch/tag'), with: ref
        wait_for_requests

        select_listbox_item(ref)
      end
      expect(ref_selector_dropdown).to have_text(ref)
    end
  end
end
