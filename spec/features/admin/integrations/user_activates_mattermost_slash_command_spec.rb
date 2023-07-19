# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates the instance-level Mattermost Slash Command integration', :js,
  feature_category: :integrations do
  include_context 'instance integration activation'

  before do
    stub_mattermost_setting(enabled: true)
    visit_instance_integration('Mattermost slash commands')
  end

  let(:edit_path) { edit_admin_application_settings_integration_path(:mattermost_slash_commands) }
  let(:overrides_path) { overrides_admin_application_settings_integration_path(:mattermost_slash_commands) }

  include_examples 'user activates the Mattermost Slash Command integration'

  it 'displays navigation tabs' do
    expect(page).to have_link('Settings', href: edit_path)
    expect(page).to have_link('Projects using custom settings', href: overrides_path)
  end
end
