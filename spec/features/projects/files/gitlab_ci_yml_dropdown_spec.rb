# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User wants to add a .gitlab-ci.yml file', :js do
  include Spec::Support::Helpers::Features::EditorLiteSpecHelpers

  before do
    project = create(:project, :repository)
    sign_in project.owner
    visit project_new_blob_path(project, 'master', file_name: '.gitlab-ci.yml')
  end

  it 'user can pick a template from the dropdown' do
    expect(page).to have_css('.gitlab-ci-yml-selector')

    find('.js-gitlab-ci-yml-selector').click

    wait_for_requests

    within '.gitlab-ci-yml-selector' do
      find('.dropdown-input-field').set('Jekyll')
      find('.dropdown-content li', text: 'Jekyll').click
    end

    wait_for_requests

    expect(page).to have_css('.gitlab-ci-yml-selector .dropdown-toggle-text', text: 'Apply a template')
    expect(editor_get_value).to have_content('This file is a template, and might need editing before it works on your project')
    expect(editor_get_value).to have_content('jekyll build -d test')
  end
end
