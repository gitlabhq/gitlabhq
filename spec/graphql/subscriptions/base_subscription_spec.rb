# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::BaseSubscription, feature_category: :system_access do
  include GraphqlHelpers

  describe '#initialize' do
    let(:context) do
      query = GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {})

      GraphQL::Query::Context.new(
        query: query,
        values: { current_user: current_user, access_token: access_token }
      )
    end

    subject(:build_subscription) { resolver_instance(described_class, ctx: context) }

    context 'when current_user and access_token are present' do
      let(:current_user) { instance_double(User) }
      let(:access_token) { instance_double(PersonalAccessToken) }

      it 'resets both so stale membership or token scope is not used for authorization' do
        expect(current_user).to receive(:reset)
        expect(access_token).to receive(:reset)

        build_subscription
      end
    end

    context 'when current_user is nil' do
      let(:current_user) { nil }
      let(:access_token) { instance_double(PersonalAccessToken) }

      it 'does not attempt to reset the user' do
        expect(access_token).to receive(:reset)

        expect { build_subscription }.not_to raise_error
      end
    end

    context 'when access_token is nil' do
      let(:current_user) { instance_double(User) }
      let(:access_token) { nil }

      it 'resets the user and does not attempt to reset the token' do
        expect(current_user).to receive(:reset)

        expect { build_subscription }.not_to raise_error
      end
    end

    context 'when access_token does not respond to reset' do
      let(:current_user) { instance_double(User) }
      let(:access_token) { Object.new }

      it 'does not attempt to reset the token' do
        expect(current_user).to receive(:reset)

        expect { build_subscription }.not_to raise_error
      end
    end
  end
end
