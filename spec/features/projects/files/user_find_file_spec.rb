# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User find project file', feature_category: :source_code_management do
  include ListboxHelpers

  let(:user)    { create :user }
  let(:project) { create :project, :repository }

  global_search_modal_selector = '#super-sidebar-search-modal'

  before do
    sign_in(user)
    project.add_maintainer(user)

    visit project_tree_path(project, project.repository.root_ref)
  end

  def find_file(text)
    fill_in 'search', with: "~#{text}"
  end

  def ref_selector_dropdown
    find('.ref-selector .gl-button-text')
  end

  it 'activates the global search modal by shortcut', :js do
    find('body').native.send_key('t')

    expect(page).to have_selector(global_search_modal_selector, count: 1)
  end

  it 'activates the global search modal when find file button is clicked', :js do
    click_button 'Find file'

    expect(page).to have_selector(global_search_modal_selector, count: 1)
  end

  it 'searches CHANGELOG file', :js do
    click_button 'Find file'

    find_file 'change'

    page.within(global_search_modal_selector) do
      expect(page).to have_content('CHANGELOG')
      expect(page).not_to have_content('.gitignore')
      expect(page).not_to have_content('VERSION')
    end
  end

  it 'does not find file when search not exist file', :js do
    click_button 'Find file'

    find_file 'asdfghjklqwertyuizxcvbnm'

    page.within(global_search_modal_selector) do
      expect(page).not_to have_content('CHANGELOG')
      expect(page).not_to have_content('.gitignore')
      expect(page).not_to have_content('VERSION')
    end
  end

  it 'searches file by partially matches', :js do
    click_button 'Find file'

    find_file 'git'

    page.within(global_search_modal_selector) do
      expect(page).to have_content('.gitignore')
      expect(page).to have_content('.gitmodules')
      expect(page).not_to have_content('CHANGELOG')
      expect(page).not_to have_content('VERSION')
    end
  end

  context 'when refs are switched', :js do
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
        fill_in _('Search by Git revision'), with: ref
        wait_for_requests

        select_listbox_item(ref)
      end
      expect(ref_selector_dropdown).to have_text(ref)
    end
  end
end
