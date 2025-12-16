# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::FeatureFlagResolver, feature_category: :feature_flags do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  describe '#resolve' do
    subject { resolve_flag_availability(feature_flag.to_s) }

    context 'when feature flag is unknown' do
      let(:feature_flag) { "unknown_feature" }

      it { is_expected.to eq(false) }
    end

    context "on feature flag resolution" do
      let(:feature_flag) { Feature::Definition.definitions.each_key.first }

      before do
        stub_feature_flags(feature_flag => enabled)
      end

      context "when feature flag disabled" do
        let(:enabled) { false }

        it { is_expected.to eq(false) }
      end

      context "when feature flag enabled" do
        let(:enabled) { true }

        it { is_expected.to eq(true) }

        context 'when user is not set' do
          let(:current_user) { nil }

          it { is_expected.to eq(false) }
        end
      end
    end
  end

  def resolve_flag_availability(name, context = { current_user: current_user })
    resolve(described_class, obj: nil, args: { name: name }, ctx: context)
  end
end
