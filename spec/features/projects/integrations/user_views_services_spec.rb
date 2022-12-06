# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views integrations', :js, feature_category: :integrations do
  include_context 'project integration activation'

  it 'shows the list of available integrations' do
    visit_project_integrations

    expect(page).to have_content('Integrations')
    expect(page).to have_content('Campfire')
    expect(page).to have_content('Jira')
    expect(page).to have_content('Assembla')
    expect(page).to have_content('Pushover')
    expect(page).to have_content('Atlassian Bamboo')
    expect(page).to have_content('JetBrains TeamCity')
    expect(page).to have_content('Asana')
    expect(page).to have_content('irker (IRC gateway)')
    expect(page).to have_content('Packagist')
  end
end
