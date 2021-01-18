# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectHelper do
  describe '#jira_connect_app_data' do
    subject { helper.jira_connect_app_data }

    it 'includes Jira Connect app attributes' do
      is_expected.to include(
        :groups_path
      )
    end
  end
end
