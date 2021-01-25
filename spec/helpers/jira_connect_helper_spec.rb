# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectHelper do
  describe '#jira_connect_app_data' do
    let_it_be(:subscription) { create(:jira_connect_subscription) }

    subject { helper.jira_connect_app_data([subscription]) }

    it 'includes Jira Connect app attributes' do
      is_expected.to include(
        :groups_path,
        :subscriptions_path
      )
    end

    it 'passes group as "skip_groups" param' do
      skip_groups_param = CGI.escape('skip_groups[]')

      expect(subject[:groups_path]).to include("#{skip_groups_param}=#{subscription.namespace.id}")
    end
  end
end
