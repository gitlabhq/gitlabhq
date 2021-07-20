# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User wants to add a .gitignore file', :js do
  include Spec::Support::Helpers::Features::SourceEditorSpecHelpers

  before do
    project = create(:project, :repository)
    sign_in project.owner
    visit project_new_blob_path(project, 'master', file_name: '.gitignore')
  end

  it 'user can pick a .gitignore file from the dropdown' do
    expect(page).to have_css('.gitignore-selector')

    find('.js-gitignore-selector').click

    wait_for_requests

    within '.gitignore-selector' do
      find('.dropdown-input-field').set('rails')
      find('.dropdown-content li', text: 'Rails').click
    end

    wait_for_requests

    expect(page).to have_css('.gitignore-selector .dropdown-toggle-text', text: 'Apply a template')
    expect(editor_get_value).to have_content('/.bundle')
    expect(editor_get_value).to have_content('config/initializers/secret_token.rb')
  end
end
