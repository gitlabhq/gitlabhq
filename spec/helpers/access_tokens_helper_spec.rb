# frozen_string_literal: true

require "spec_helper"

RSpec.describe AccessTokensHelper, feature_category: :system_access do
  describe "#scope_description" do
    using RSpec::Parameterized::TableSyntax

    where(:prefix, :description_location) do
      :personal_access_token  | [:doorkeeper, :scope_desc]
      :project_access_token   | [:doorkeeper, :project_access_token_scope_desc]
      :group_access_token     | [:doorkeeper, :group_access_token_scope_desc]
    end

    with_them do
      it { expect(helper.scope_description(prefix)).to eq(description_location) }
    end
  end

  describe '#tokens_app_data' do
    let_it_be(:feed_token) { 'DUKu345VD73Py7zz3z89' }
    let_it_be(:incoming_email_token) { 'az4a2l5f8ssa0zvdfbhidbzlx' }
    let_it_be(:static_object_token) { 'QHXwGHYioHTgxQnAcyZ-' }
    let_it_be(:feed_token_reset_path) { '/-/profile/reset_feed_token' }
    let_it_be(:incoming_email_token_reset_path) { '/-/profile/reset_incoming_email_token' }
    let_it_be(:static_object_token_reset_path) { '/-/profile/reset_static_object_token' }
    let_it_be(:user) do
      build(
        :user,
        feed_token: feed_token,
        incoming_email_token: incoming_email_token,
        static_object_token: static_object_token
      )
    end

    it 'returns expected json' do
      allow(Gitlab::CurrentSettings).to receive_messages(
        disable_feed_token: false,
        static_objects_external_storage_enabled?: true
      )
      allow(Gitlab::Email::IncomingEmail).to receive(:supports_issue_creation?).and_return(true)
      allow(helper).to receive_messages(
        current_user: user,
        reset_feed_token_profile_path: feed_token_reset_path,
        reset_incoming_email_token_profile_path: incoming_email_token_reset_path,
        reset_static_object_token_profile_path: static_object_token_reset_path
      )

      expect(helper.tokens_app_data).to eq({
        feed_token: {
          enabled: true,
          token: feed_token,
          reset_path: feed_token_reset_path
        },
        incoming_email_token: {
          enabled: true,
          token: incoming_email_token,
          reset_path: incoming_email_token_reset_path
        },
        static_object_token: {
          enabled: true,
          token: static_object_token,
          reset_path: static_object_token_reset_path
        }
      }.to_json)
    end
  end

  describe '#expires_at_field_data', :freeze_time do
    before do
      # Test the CE version of `expires_at_field_data` by satisfying the condition in the EE
      # that calls the `super` method.
      allow(helper).to receive(:personal_access_token_expiration_policy_enabled?).and_return(false)
    end

    it 'returns expected hash' do
      expect(helper.expires_at_field_data).to eq({
        min_date: 1.day.from_now.iso8601,
        max_date: 400.days.from_now.iso8601
      })
    end

    context 'when require_personal_access_token_expiry is false' do
      before do
        stub_application_setting(require_personal_access_token_expiry: false)
      end

      it 'returns an empty hash' do
        expect(helper.expires_at_field_data).to eq({
          min_date: 1.day.from_now.iso8601,
          max_date: nil
        })
      end
    end
  end
end
