# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard shortcuts', :js do
  context 'logged in' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }

    before do
      project.add_developer(user)
      sign_in(user)
      visit root_dashboard_path
    end

    it 'Navigate to tabs' do
      find('body').send_keys([:shift, 'I'])

      check_page_title('Issues')

      find('body').send_keys([:shift, 'M'])

      check_page_title('Merge Requests')

      find('body').send_keys([:shift, 'T'])

      check_page_title('To-Do List')

      find('body').send_keys([:shift, 'P'])

      check_page_title('Projects')
    end
  end

  context 'logged out' do
    before do
      visit explore_root_path
    end

    it 'Navigate to tabs' do
      find('body').send_keys([:shift, 'G'])

      find('.nothing-here-block')
      expect(page).to have_content('No public groups')

      find('body').send_keys([:shift, 'S'])

      find('.nothing-here-block')
      expect(page).to have_content('No snippets found')

      find('body').send_keys([:shift, 'P'])

      find('.nothing-here-block')
      expect(page).to have_content('This user doesn\'t have any personal projects')
    end
  end

  def check_page_title(title)
    expect(find('.page-title')).to have_content(title)
  end
end
