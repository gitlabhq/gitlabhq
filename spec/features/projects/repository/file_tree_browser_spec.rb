# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Repository file tree browser', :js, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, :with_namespace) }

  before_all do
    project.add_developer(user)
  end

  before do
    sign_in(user)
    stub_feature_flags(repository_file_tree_browser: true)
    visit project_tree_path(project, project.default_branch)
    wait_for_requests
    click_button 'Show file tree browser'
  end

  describe 'basic functionality' do
    it 'shows and hides the file tree browser' do
      if Users::ProjectStudio.enabled_for_user?(user) # rubocop:disable RSpec/AvoidConditionalStatements -- temporary Project Studio rollout
        expect(page).to have_css('.file-tree-browser-peek')
      else
        expect(page).to have_css('.file-tree-browser-expanded')
      end

      click_button 'Hide file tree browser'
      wait_for_requests

      if Users::ProjectStudio.enabled_for_user?(user) # rubocop:disable RSpec/AvoidConditionalStatements -- temporary Project Studio rollout
        expect(page).not_to have_css('.file-tree-browser-peek')
      else
        expect(page).not_to have_css('.file-tree-browser-expanded')
      end
    end

    it 'displays files and directories' do
      within('.file-tree-browser') do
        expect(page).to have_file('README.md')
        expect(page).to have_file('files')
      end
    end

    it 'passes axe automated accessibility testing' do
      expect(page).to be_axe_clean.within('.file-tree-browser')
    end

    it 'navigates to a file' do
      within('.file-tree-browser') do
        click_file('README.md')
      end

      expect(page).to have_current_path(project_blob_path(project, "#{project.default_branch}/README.md"))
    end

    it 'expands and collapses directories' do
      within('.file-tree-browser') do
        click_button('Expand files directory')
        expect(page).to have_file('ruby')

        click_button('Collapse files directory')
        expect(page).not_to have_file('ruby')
      end
    end

    it 'expands parent directories when navigating directly to a nested file' do
      visit project_blob_path(project, "#{project.default_branch}/files/ruby/popen.rb")
      wait_for_requests

      within('.file-tree-browser') do
        # Should auto-expand parent directories
        files_folder = find_button('files')
        expect(files_folder[:class]).to include('is-open')

        ruby_folder = find_button('ruby')
        expect(ruby_folder[:class]).to include('is-open')

        # Should highlight the current file
        expect(find('[aria-current="true"]')).to be_present
      end
    end
  end

  describe 'filtering' do
    it 'filters files by name' do
      within('.file-tree-browser') do
        fill_in 'Filter input', with: 'README'

        expect(page).to have_file('README.md')
        expect(page).not_to have_file('files')
      end
    end

    it 'shows no results message when nothing matches' do
      within('.file-tree-browser') do
        fill_in 'Filter input', with: 'nonexistent'

        expect(page).to have_content('No files found')
      end
    end
  end

  describe 'keyboard shortcuts' do
    it 'focuses filter with f key' do
      # This key is registered as a shortcut for focusing the filter bar
      send_keys('f')

      expect(page).to have_css('input[aria-label="Filter input"]:focus')
    end

    it 'toggles visibility with Shift+f' do
      send_keys([:shift, 'f'])

      expect(page).not_to have_css('.file-tree-browser-expanded')
    end
  end

  describe 'when feature flag is disabled' do
    before do
      stub_feature_flags(repository_file_tree_browser: false)
      visit project_tree_path(project, project.default_branch)
      wait_for_requests
    end

    it 'does not show file tree browser toggle' do
      expect(page).not_to have_css('#file-tree-browser-toggle')
    end
  end

  private

  def click_file(name)
    find(".file-row[aria-label=\"#{name}\"]").click
    wait_for_requests
  end

  def have_file(name)
    have_css(".file-row[aria-label=\"#{name}\"]")
  end
end
