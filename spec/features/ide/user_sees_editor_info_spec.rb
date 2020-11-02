# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'IDE user sees editor info', :js do
  include WebIdeSpecHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { project.owner }

  before do
    sign_in(user)

    ide_visit(project)
  end

  it 'shows line position' do
    ide_open_file('README.md')

    within find('.ide-status-bar') do
      expect(page).to have_content('1:1')
    end

    ide_set_editor_position(4, 10)

    within find('.ide-status-bar') do
      expect(page).not_to have_content('1:1')
      expect(page).to have_content('4:10')
    end
  end

  it 'updates after rename' do
    ide_open_file('README.md')
    ide_set_editor_position(4, 10)

    within find('.ide-status-bar') do
      expect(page).to have_content('markdown')
      expect(page).to have_content('4:10')
    end

    ide_rename_file('README.md', 'READMEZ.txt')

    within find('.ide-status-bar') do
      expect(page).to have_content('plaintext')
      expect(page).to have_content('1:1')
    end
  end

  it 'persists position after rename' do
    ide_open_file('README.md')
    ide_set_editor_position(4, 10)

    ide_open_file('files/js/application.js')
    ide_rename_file('README.md', 'READING_RAINBOW.md')

    ide_open_file('READING_RAINBOW.md')

    within find('.ide-status-bar') do
      expect(page).to have_content('4:10')
    end
  end

  it 'persists position' do
    ide_open_file('README.md')
    ide_set_editor_position(4, 10)

    ide_close_file('README.md')
    ide_open_file('README.md')

    within find('.ide-status-bar') do
      expect(page).to have_content('markdown')
      expect(page).to have_content('4:10')
    end
  end

  it 'persists viewer' do
    ide_open_file('README.md')
    click_link('Preview Markdown')

    within find('.md-previewer') do
      expect(page).to have_content('testme')
    end

    # Switch away from and back to the file
    ide_open_file('.gitignore')
    ide_open_file('README.md')

    # Preview is still enabled
    within find('.md-previewer') do
      expect(page).to have_content('testme')
    end
  end
end
