# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User wants to add a Dockerfile file', :js, feature_category: :source_code_management do
  include Features::SourceEditorSpecHelpers

  before do
    project = create(:project, :repository)
    sign_in project.first_owner
    visit project_new_blob_path(project, 'master', file_name: 'Dockerfile')
  end

  it 'user can pick a Dockerfile file from the dropdown' do
    click_button 'Apply a template'

    within '.gl-new-dropdown-panel' do
      find('.gl-listbox-search-input').set('HTTPd')
      find('.gl-new-dropdown-contents li', text: 'HTTPd').click
    end

    wait_for_requests

    expect(page).to have_css('.gl-new-dropdown-button-text', text: 'HTTPd')
    expect(find('.monaco-editor')).to have_content('COPY ./ /usr/local/apache2/htdocs/')
  end
end
