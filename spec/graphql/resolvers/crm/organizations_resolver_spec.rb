# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Crm::OrganizationsResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :crm_enabled) }

  let_it_be(:organization_a) do
    create(
      :organization,
      group: group,
      name: "ABC",
      state: "inactive"
    )
  end

  let_it_be(:organization_b) do
    create(
      :organization,
      group: group,
      name: "DEF",
      state: "active"
    )
  end

  describe '#resolve' do
    context 'with unauthorized user' do
      it 'does not rise an error and returns no organizations' do
        expect { resolve_organizations(group) }.not_to raise_error
        expect(resolve_organizations(group)).to be_empty
      end
    end

    context 'with authorized user' do
      it 'does not rise an error and returns all organizations' do
        group.add_reporter(user)

        expect { resolve_organizations(group) }.not_to raise_error
        expect(resolve_organizations(group)).to eq([organization_a, organization_b])
      end
    end

    context 'without parent' do
      it 'returns no organizations' do
        expect(resolve_organizations(nil)).to be_empty
      end
    end

    context 'with a group parent' do
      before do
        group.add_developer(user)
      end

      context 'when no filter is provided' do
        it 'returns all the organizations' do
          expect(resolve_organizations(group)).to match_array([organization_a, organization_b])
        end
      end

      context 'when search term is provided' do
        it 'returns the correct organizations' do
          expect(resolve_organizations(group, { search: "def" })).to match_array([organization_b])
        end
      end

      context 'when state is provided' do
        it 'returns the correct organizations' do
          expect(resolve_organizations(group, { state: :inactive })).to match_array([organization_a])
        end
      end
    end
  end

  def resolve_organizations(parent, args = {}, context = { current_user: user })
    resolve(described_class, obj: parent, args: args, ctx: context)
  end
end
