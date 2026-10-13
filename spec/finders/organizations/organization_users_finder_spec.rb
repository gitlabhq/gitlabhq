# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationUsersFinder, feature_category: :organization do
  let_it_be_with_reload(:organization) { create(:organization) }
  let_it_be(:organization_owner) { create(:organization_owner, organization: organization) }
  let_it_be(:organization_user) { create(:organization_user, organization: organization) }
  let_it_be(:other_organization_user) { create(:organization_user) }

  let(:current_user) { organization_owner.user }
  let(:search) { nil }
  let(:finder) { described_class.new(organization: organization, current_user: current_user, search: search) }

  subject(:result) { finder.execute.to_a }

  describe '#execute' do
    context 'when user is not authorized to read the organization users' do
      let(:current_user) { organization_user.user }

      it { is_expected.to be_empty }
    end

    context 'when organization is nil' do
      let(:organization) { nil }

      it { is_expected.to be_empty }
    end

    context 'when user is authorized to read the organization users' do
      it 'returns all organization users' do
        expect(result).to contain_exactly(organization_owner, organization_user)
      end

      context 'when searching' do
        let_it_be(:searched_user) { create(:user, organizations: [], name: 'Jane Searchable', username: 'jsearch') }
        let_it_be(:searched_organization_user) do
          create(:organization_user, organization: organization, user: searched_user)
        end

        let_it_be(:outside_user) { create(:user, organizations: [], name: 'Jane Searchable', username: 'jsearch2') }
        let_it_be(:outside_organization_user) { create(:organization_user, user: outside_user) }

        context 'when search matches the name' do
          let(:search) { 'searchable' }

          it 'returns only matching organization users of the organization' do
            expect(result).to contain_exactly(searched_organization_user)
          end
        end

        context 'when search matches the username' do
          let(:search) { 'jsea' }

          it { is_expected.to contain_exactly(searched_organization_user) }
        end

        context 'when search is too short for partial matching' do
          let(:search) { 'js' }

          it { is_expected.to be_empty }
        end

        context 'when search is an empty string' do
          let(:search) { '' }

          it 'returns all organization users' do
            expect(result).to contain_exactly(organization_owner, organization_user, searched_organization_user)
          end
        end
      end
    end
  end
end
