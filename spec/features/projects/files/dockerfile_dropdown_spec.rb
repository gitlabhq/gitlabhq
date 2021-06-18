# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User wants to add a Dockerfile file', :js do
  include Spec::Support::Helpers::Features::SourceEditorSpecHelpers

  before do
    project = create(:project, :repository)
    sign_in project.owner
    visit project_new_blob_path(project, 'master', file_name: 'Dockerfile')
  end

  it 'user can pick a Dockerfile file from the dropdown' do
    expect(page).to have_css('.dockerfile-selector')

    find('.js-dockerfile-selector').click

    wait_for_requests

    within '.dockerfile-selector' do
      find('.dropdown-input-field').set('HTTPd')
      find('.dropdown-content li', text: 'HTTPd').click
    end

    wait_for_requests

    expect(page).to have_css('.dockerfile-selector .dropdown-toggle-text', text: 'Apply a template')
    expect(editor_get_value).to have_content('COPY ./ /usr/local/apache2/htdocs/')
  end
end
