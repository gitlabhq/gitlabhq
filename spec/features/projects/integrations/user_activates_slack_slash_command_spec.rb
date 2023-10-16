# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Slack slash commands', :js, feature_category: :integrations do
  include_context 'project integration activation'

  before do
    visit_project_integration('Slack slash commands')
  end

  it 'shows a token placeholder' do
    token_placeholder = find_field('Token')['placeholder']

    expect(token_placeholder).to eq('')
  end

  it 'shows a help message' do
    expect(page).to have_content('Perform common operations in this project')
  end

  it 'redirects to the integrations page after saving but not activating' do
    fill_in 'Token', with: 'token'
    click_active_checkbox
    click_on 'Save'

    expect(page).to have_current_path(
      edit_project_settings_integration_path(project, :slack_slash_commands),
      ignore_query: true
    )

    expect(page).to have_content('Slack slash commands settings saved, but not active.')
  end

  it 'redirects to the integrations page after activating' do
    fill_in 'Token', with: 'token'
    click_on 'Save'

    expect(page).to have_current_path(
      edit_project_settings_integration_path(project, :slack_slash_commands),
      ignore_query: true
    )

    expect(page).to have_content('Slack slash commands settings saved and active.')
  end

  it 'shows the correct trigger url' do
    value = find_field('url').value
    expect(value).to match("api/v4/projects/#{project.id}/integrations/slack_slash_commands/trigger")
  end

  it 'shows help content' do
    expect(page).to have_content('Perform common operations in this project by entering slash commands in Slack.')
  end
end
