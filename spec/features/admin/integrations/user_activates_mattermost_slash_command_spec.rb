# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates the instance-level Mattermost Slash Command integration', :js do
  include_context 'instance integration activation'

  before do
    stub_mattermost_setting(enabled: true)
    visit_instance_integration('Mattermost slash commands')
  end

  let(:edit_path) { edit_admin_application_settings_integration_path(:mattermost_slash_commands) }

  include_examples 'user activates the Mattermost Slash Command integration'
end
