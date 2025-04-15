# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::JobInterfaceBaseField, feature_category: :continuous_integration do
  describe 'authorized?' do
    let(:current_user) { instance_double(User) }
    let(:object) { instance_double(Ci::Build) }
    let(:ctx) { { current_user: current_user } }

    subject(:field) do
      described_class.new(name: :name, type: GraphQL::Types::String, null: true)
    end

    context 'when user has :read_build ability on the object' do
      it 'returns true' do
        expect(Ability).to receive(:allowed?).with(current_user, :read_build, object).and_return(true)

        is_expected.to be_authorized(object, nil, ctx)
      end
    end

    context 'when user does not have :read_build ability on the object' do
      it 'returns false' do
        expect(Ability).to receive(:allowed?).with(current_user, :read_build, object).and_return(false)

        is_expected.not_to be_authorized(object, nil, ctx)
      end
    end
  end
end
