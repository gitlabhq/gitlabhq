# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views services', :js do
  include_context 'project service activation'

  it 'shows the list of available services' do
    visit_project_integrations

    expect(page).to have_content('Integrations')
    expect(page).to have_content('Campfire')
    expect(page).to have_content('Jira')
    expect(page).to have_content('Assembla')
    expect(page).to have_content('Pushover')
    expect(page).to have_content('Atlassian Bamboo')
    expect(page).to have_content('JetBrains TeamCity')
    expect(page).to have_content('Asana')
    expect(page).to have_content('Irker (IRC gateway)')
    expect(page).to have_content('Packagist')
  end
end
