# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Namespace factory', feature_category: :groups_and_projects do
  describe 'owner' do
    subject(:created_factory) { create(:namespace) }

    it 'assigns a user as owner' do
      expect(created_factory.owner).to be_a_kind_of(User)
    end

    context 'when an organization is passed to the factory' do
      let(:organization) { create(:organization) }

      subject(:created_factory) { create(:namespace, organization: organization) }

      it 'ensures the owner is in the same organization' do
        expect(created_factory.owner.organization).to eq(organization)
      end
    end
  end
end
