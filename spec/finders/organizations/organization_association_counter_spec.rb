# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationAssociationCounter, feature_category: :cell do
  let_it_be(:other_organization) { create(:organization) }
  let_it_be(:organization) { create(:organization) }
  let_it_be(:owner) { create(:organization_user, :owner, organization: organization) }

  let(:current_user) { owner.user }
  let(:finder) { described_class.new(organization: organization, current_user: current_user) }

  before_all do
    create_pair(:organization_user, organization: organization)
    create_list(:project, 3, :small_repo, organization: organization)
    create_list(:group, 3, organization: organization)

    create(:organization_user, organization: other_organization)
    create(:project, :small_repo, organization: other_organization)
    create(:group, organization: other_organization)
  end

  subject(:result) { finder.execute }

  describe '#execute' do
    context 'when user is not owner of the organization' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_empty }
    end

    context 'when organization is nil' do
      let(:organization) { nil }

      it { is_expected.to be_empty }
    end

    context 'when user is owner of the organization' do
      it 'returns correct counts' do
        expect(result).to match(a_hash_including({
          groups: '3',
          projects: '3',
          users: '6'
        }))
      end

      context 'when counts are over the limit' do
        before do
          stub_const("#{described_class}::COUNTER_LIMIT", 2)
        end

        it 'returns limited counts' do
          expect(result).to match(a_hash_including({
            groups: '2+',
            projects: '2+',
            users: '2+'
          }))
        end
      end
    end
  end
end
