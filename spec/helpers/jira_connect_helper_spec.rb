# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectHelper, feature_category: :integrations do
  describe '#jira_connect_app_data' do
    let_it_be(:installation) { create(:jira_connect_installation) }
    let_it_be(:subscription) { create(:jira_connect_subscription) }

    let(:user) { create(:user) }
    let(:client_id) { '123' }
    let(:enable_public_keys_storage) { false }

    before do
      stub_application_setting(jira_connect_application_key: client_id)
    end

    subject { helper.jira_connect_app_data([subscription], installation) }

    context 'user is not logged in' do
      before do
        allow(view).to receive(:current_user).and_return(nil)
        allow(Gitlab.config.gitlab).to receive(:url).and_return('http://test.host')
        stub_application_setting(jira_connect_public_key_storage_enabled: enable_public_keys_storage)
      end

      it 'includes Jira Connect app attributes' do
        is_expected.to include(
          :groups_path,
          :subscriptions_path,
          :subscriptions,
          :gitlab_user_path
        )
      end

      context 'with oauth_metadata' do
        let(:oauth_metadata) { helper.jira_connect_app_data([subscription], installation)[:oauth_metadata] }

        subject(:parsed_oauth_metadata) { Gitlab::Json.parse(oauth_metadata).deep_symbolize_keys }

        it 'assigns oauth_metadata' do
          expect(parsed_oauth_metadata).to include(
            oauth_authorize_url: start_with('http://test.host/oauth/authorize?'),
            oauth_token_path: '/oauth/token',
            state: %r/[a-z0-9.]{32}/,
            oauth_token_payload: hash_including(
              grant_type: 'authorization_code',
              client_id: client_id,
              redirect_uri: 'http://test.host/-/jira_connect/oauth_callbacks'
            )
          )
        end

        it 'includes oauth_authorize_url with all params' do
          params = Rack::Utils.parse_nested_query(URI.parse(parsed_oauth_metadata[:oauth_authorize_url]).query)

          expect(params).to include(
            'client_id' => client_id,
            'response_type' => 'code',
            'scope' => 'api',
            'redirect_uri' => 'http://test.host/-/jira_connect/oauth_callbacks',
            'state' => parsed_oauth_metadata[:state]
          )
        end

        context 'with self-managed instance' do
          let_it_be(:installation) { create(:jira_connect_installation, instance_url: 'https://gitlab.example.com') }

          it 'points urls to the self-managed instance' do
            expect(parsed_oauth_metadata).to include(
              oauth_authorize_url: start_with('https://gitlab.example.com/oauth/authorize?'),
              oauth_token_path: '/oauth/token'
            )
          end

          context 'with relative_url_root' do
            let_it_be(:installation) { create(:jira_connect_installation, instance_url: 'https://gitlab.example.com/gitlab') }

            before do
              stub_config_setting(relative_url_root: '/gitlab')
              allow(Rails.application.routes).to receive(:default_url_options).and_return(script_name: '/gitlab')
            end

            it 'points urls to the self-managed instance' do
              expect(parsed_oauth_metadata).to include(
                oauth_authorize_url: start_with('https://gitlab.example.com/gitlab/oauth/authorize?'),
                oauth_token_path: '/gitlab/oauth/token'
              )
            end
          end
        end
      end

      it 'passes group as comma-separated skip_groups param' do
        expect(subject[:groups_path]).to include("skip_groups=#{subscription.namespace.id}")
      end

      it 'assigns gitlab_user_path to nil' do
        expect(subject[:gitlab_user_path]).to be_nil
      end

      it 'assignes public_key_storage_enabled to false' do
        expect(subject[:public_key_storage_enabled]).to eq(false)
      end

      context 'when public_key_storage is enabled' do
        let(:enable_public_keys_storage) { true }

        it 'assignes public_key_storage_enabled to true' do
          expect(subject[:public_key_storage_enabled]).to eq(true)
        end
      end
    end

    context 'user is logged in' do
      before do
        allow(view).to receive(:current_user).and_return(user)
      end

      it 'assigns users_path to nil' do
        expect(subject[:users_path]).to be_nil
      end

      it 'assigns gitlab_user_path correctly' do
        expect(subject[:gitlab_user_path]).to eq(user_path(user))
      end
    end
  end
end
