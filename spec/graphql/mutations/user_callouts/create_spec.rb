# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::UserCallouts::Create do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  describe '#resolve' do
    subject(:resolve) { mutation.resolve(feature_name: feature_name) }

    context 'when feature name is not supported' do
      let(:feature_name) { 'not_supported' }

      it 'does not create a user callout' do
        expect { resolve }.not_to change(Users::Callout, :count).from(0)
      end

      it 'returns error about feature name not being supported' do
        expect(resolve[:errors]).to include("Feature name is not included in the list")
      end
    end

    context 'when feature name is supported' do
      let(:feature_name) { Users::Callout.feature_names.each_key.first.to_s }

      it 'creates a user callout' do
        expect { resolve }.to change(Users::Callout, :count).from(0).to(1)
      end

      it 'sets dismissed_at for the user callout' do
        freeze_time do
          expect(resolve[:user_callout].dismissed_at).to eq(Time.current)
        end
      end

      it 'has no errors' do
        expect(resolve[:errors]).to be_empty
      end
    end
  end
end
