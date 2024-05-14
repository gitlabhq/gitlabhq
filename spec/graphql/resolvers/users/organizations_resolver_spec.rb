# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Users::OrganizationsResolver, feature_category: :navigation do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:organization) do
    create(:organization).tap do |o|
      create(:organization_user, organization: o, user: user)
    end
  end

  let_it_be(:organization_2) do
    create(:organization).tap do |o|
      create(:organization_user, organization: o, user: user)
    end
  end

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
