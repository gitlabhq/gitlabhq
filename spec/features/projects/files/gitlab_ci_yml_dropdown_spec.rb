# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User wants to add a .gitlab-ci.yml file', :js, feature_category: :source_code_management do
  include Features::SourceEditorSpecHelpers

  let(:params) { {} }
  let(:filename) { '.gitlab-ci.yml' }

  let_it_be(:project) { create(:project, :repository) }

  before do
    sign_in project.first_owner
    visit project_new_blob_path(project, 'master', file_name: filename, **params)
  end

  it 'user can pick a template from the dropdown' do
    click_button 'Apply a template'

    within '.gl-new-dropdown-panel' do
      find('.gl-listbox-search-input').set('Jekyll')
      find('.gl-new-dropdown-contents li', text: 'Jekyll').click
    end

    wait_for_requests

    expect(page).to have_css('.gl-new-dropdown-button-text', text: 'Jekyll')
    expect(find('.monaco-editor')).to have_content('This file is a template, and might need editing before it works on your project')
    expect(find('.monaco-editor')).to have_content('jekyll build -d test')
  end

  context 'when template param is provided' do
    let(:params) { { template: 'Jekyll' } }

    it 'uses the given template' do
      wait_for_requests

      expect(page).to have_css('.gl-new-dropdown-button-text', text: 'Jekyll')
      expect(find('.monaco-editor')).to have_content('This file is a template, and might need editing before it works on your project')
      expect(find('.monaco-editor')).to have_content('jekyll build -d test')
    end
  end

  context 'when provided template param is not a valid template name' do
    let(:params) { { template: 'non-existing-template' } }

    it 'leaves the editor empty' do
      wait_for_requests

      expect(page).to have_css('.gl-new-dropdown-button-text', text: 'Apply a template')
      expect(find('.monaco-editor')).to have_content('')
    end
  end

  context 'when template is not available for the given file' do
    let(:filename) { 'Dockerfile' }
    let(:params) { { template: 'Jekyll' } }

    it 'leaves the editor empty' do
      wait_for_requests

      expect(find('.monaco-editor')).to have_content('')
    end
  end
end
