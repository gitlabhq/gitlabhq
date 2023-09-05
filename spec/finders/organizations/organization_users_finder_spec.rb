# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationUsersFinder, feature_category: :cell do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:organization_user_1) { create(:organization_user, organization: organization) }
  let_it_be(:organization_user_2) { create(:organization_user, organization: organization) }
  let_it_be(:other_organization_user) { create(:organization_user) }

  let(:current_user) { organization_user_1.user }
  let(:finder) { described_class.new(organization: organization, current_user: current_user) }

  subject(:result) { finder.execute.to_a }

  describe '#execute' do
    context 'when user is not authorized to read the organization' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_empty }
    end

    context 'when organization is nil' do
      let(:organization) { nil }

      it { is_expected.to be_empty }
    end

    context 'when user is authorized to read the organization' do
      it 'returns all organization users' do
        expect(result).to contain_exactly(organization_user_1, organization_user_2)
      end
    end
  end
end
