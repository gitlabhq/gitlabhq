# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Namespaces::GroupBaseField, feature_category: :groups_and_projects do
  describe 'authorized?' do
    let(:current_user) { instance_double(User) }
    let(:object) { instance_double(Group) }
    let(:ctx) { { current_user: current_user } }

    subject(:field) do
      described_class.new(name: :name, type: GraphQL::Types::String, null: true)
    end

    it 'checks :read_group ability on the object' do
      expect(Ability).to receive(:allowed?).with(current_user, :read_group, object).and_return(false)

      is_expected.not_to be_authorized(object, nil, ctx)
    end
  end
end
