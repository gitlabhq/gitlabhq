# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Users::OrganizationsResolver, feature_category: :navigation do
  using RSpec::Parameterized::TableSyntax

  include GraphqlHelpers

  let_it_be(:organization) { create(:organization) }
  let_it_be(:organization_2) { create(:organization) }

  let_it_be(:user) { create(:user, organizations: [organization, organization_2]) }

  context 'with `read_user_organizations` ability' do
    let(:current_user) { user }

    it 'returns organizations for the current user' do
      expect(resolve_organizations).to contain_exactly(organization, organization_2)
    end

    context 'with search argument' do
      it 'returns organizations that matches search' do
        expect(resolve_organizations(args: { search: organization.path })).to contain_exactly(organization)
      end
    end

    context 'with solo_owned argument' do
      let_it_be(:organization_owner) { user }

      let_it_be(:solo_owned_organizations) do
        create_list(:organization_owner, 2, user: organization_owner).map(&:organization)
      end

      let_it_be(:multi_owned_organization) do
        create(:organization, organization_users: [
          create(:organization_owner, user: organization_owner),
          create(:organization_owner, user: create(:user))
        ])
      end

      let_it_be(:all_organizations) do
        [organization, organization_2, *solo_owned_organizations, multi_owned_organization]
      end

      where :solo_owned, :description, :result do
        nil | 'returns all user organizations' | ref(:all_organizations)
        false | 'returns all user organizations' | ref(:all_organizations)
        true | 'returns solo-owned organizations only' | ref(:solo_owned_organizations)
      end

      subject { resolve_organizations(args: { solo_owned: solo_owned }).items.map(&:id) }

      with_them do
        it description do
          is_expected.to match_array(result.map(&:id))
        end
      end
    end
  end

  context 'without `read_user_organizations` ability' do
    let(:current_user) { nil }

    it 'returns nil' do
      expect(resolve_organizations).to be_nil
    end
  end

  def resolve_organizations(args: {}, context_user: current_user, obj: user)
    context = { current_user: context_user }
    resolve(described_class, args: args, ctx: context, obj: obj)
  end
end
