# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::FeatureFlagResolver, feature_category: :feature_flags do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let(:feature_flag) { "some_feature" }

  describe '#resolve' do
    context "on feature flag resolution" do
      before do
        allow(Feature).to receive(:enabled?).with(feature_flag.to_sym, current_user).and_return(enabled)
      end

      context "when feature flag disabled" do
        let(:enabled) { false }

        it "returns `false`" do
          expect(resolve_flag_availability(feature_flag.to_s)).to eq false
        end
      end

      context "when feature flag enabled" do
        let(:enabled) { true }

        it "returns `true`" do
          expect(resolve_flag_availability(feature_flag.to_s)).to eq true
        end
      end
    end
  end

  def resolve_flag_availability(name, context = { current_user: current_user })
    resolve(described_class, obj: nil, args: { name: name }, ctx: context)
  end
end
