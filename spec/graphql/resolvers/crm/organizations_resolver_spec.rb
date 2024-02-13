# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Crm::OrganizationsResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let_it_be(:crm_organization_a) do
    create(
      :crm_organization,
      group: group,
      name: "ABC",
      state: "inactive"
    )
  end

  let_it_be(:crm_organization_b) do
    create(
      :crm_organization,
      group: group,
      name: "DEF",
      state: "active"
    )
  end

  describe '#resolve' do
    context 'with unauthorized user' do
      it 'does not rise an error and returns no crm_organizations' do
        expect { resolve_organizations(group) }.not_to raise_error
        expect(resolve_organizations(group)).to be_empty
      end
    end

    context 'with authorized user' do
      it 'does not rise an error and returns all crm_organizations in the correct order' do
        group.add_reporter(user)

        expect { resolve_organizations(group) }.not_to raise_error
        expect(resolve_organizations(group)).to eq([crm_organization_a, crm_organization_b])
      end
    end

    context 'without parent' do
      it 'returns no crm_organizations' do
        expect(resolve_organizations(nil)).to be_empty
      end
    end

    context 'with a group parent' do
      before do
        group.add_developer(user)
      end

      context 'when no filter is provided' do
        it 'returns all the crm_organizations in the default order' do
          expect(resolve_organizations(group)).to eq([crm_organization_a, crm_organization_b])
        end
      end

      context 'when a sort is provided' do
        it 'returns all the crm_organizations in the correct order' do
          expect(resolve_organizations(group, { sort: 'NAME_DESC' })).to eq([crm_organization_b, crm_organization_a])
        end
      end

      context 'when filtering for all states' do
        it 'returns all the crm_organizations' do
          expect(resolve_organizations(group, { state: 'all' })).to contain_exactly(
            crm_organization_a, crm_organization_b
          )
        end
      end

      context 'when search term is provided' do
        it 'returns the correct crm_organizations' do
          expect(resolve_organizations(group, { search: "def" })).to contain_exactly(crm_organization_b)
        end
      end

      context 'when state is provided' do
        it 'returns the correct crm_organizations' do
          expect(resolve_organizations(group, { state: :inactive })).to contain_exactly(crm_organization_a)
        end
      end

      context 'when ids are provided' do
        it 'returns the correct crm_organizations' do
          expect(resolve_organizations(group, {
            ids: [crm_organization_b.to_global_id]
          })).to contain_exactly(crm_organization_b)
        end
      end
    end
  end

  def resolve_organizations(parent, args = {}, context = { current_user: user })
    resolve(described_class, obj: parent, args: args, ctx: context)
  end
end
