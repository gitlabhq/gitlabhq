# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User wants to add a .gitignore file', :js, feature_category: :source_code_management do
  include Features::SourceEditorSpecHelpers

  before do
    project = create(:project, :repository)
    sign_in project.first_owner
    visit project_new_blob_path(project, 'master', file_name: '.gitignore')
  end

  it 'user can pick a .gitignore file from the dropdown' do
    click_button 'Apply a template'

    within '.gl-new-dropdown-panel' do
      find('.gl-listbox-search-input').set('rails')
      find('.gl-new-dropdown-contents li', text: 'Rails').click
    end

    wait_for_requests

    expect(page).to have_css('.gl-new-dropdown-button-text', text: 'Rails')
    expect(find('.monaco-editor')).to have_content('/.bundle')
    expect(find('.monaco-editor')).to have_content('config/initializers/secret_token.rb')
  end
end
