# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectHelper do
  describe '#jira_connect_app_data' do
    let_it_be(:subscription) { create(:jira_connect_subscription) }

    let(:user) { create(:user) }

    subject { helper.jira_connect_app_data([subscription]) }

    context 'user is not logged in' do
      before do
        allow(view).to receive(:current_user).and_return(nil)
      end

      it 'includes Jira Connect app attributes' do
        is_expected.to include(
          :groups_path,
          :subscriptions_path,
          :users_path
        )
      end

      it 'assigns users_path with value' do
        expect(subject[:users_path]).to eq(jira_connect_users_path)
      end

      it 'passes group as "skip_groups" param' do
        skip_groups_param = CGI.escape('skip_groups[]')

        expect(subject[:groups_path]).to include("#{skip_groups_param}=#{subscription.namespace.id}")
      end
    end

    context 'user is logged in' do
      before do
        allow(view).to receive(:current_user).and_return(user)
      end

      it 'assigns users_path to nil' do
        expect(subject[:users_path]).to be_nil
      end
    end
  end
end
