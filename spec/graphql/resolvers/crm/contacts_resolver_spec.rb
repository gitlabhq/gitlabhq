# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Crm::ContactsResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let_it_be(:contact_a) do
    create(
      :contact,
      group: group,
      first_name: "ABC",
      last_name: "DEF",
      email: "ghi@test.com",
      description: "LMNO",
      organization: create(:crm_organization, group: group),
      state: "inactive"
    )
  end

  let_it_be(:contact_b) do
    create(
      :contact,
      group: group,
      first_name: "PQR",
      last_name: "STU",
      email: "vwx@test.com",
      description: "YZ",
      state: "active"
    )
  end

  describe '#resolve' do
    context 'with unauthorized user' do
      it 'does not rise an error and returns no contacts' do
        expect { resolve_contacts(group) }.not_to raise_error
        expect(resolve_contacts(group)).to be_empty
      end
    end

    context 'with authorized user' do
      it 'does not rise an error and returns all contacts in the correct order' do
        group.add_reporter(user)

        expect { resolve_contacts(group) }.not_to raise_error
        expect(resolve_contacts(group)).to eq([contact_a, contact_b])
      end
    end

    context 'without parent' do
      it 'returns no contacts' do
        expect(resolve_contacts(nil)).to be_empty
      end
    end

    context 'with a group parent' do
      before do
        group.add_developer(user)
      end

      context 'when no filter is provided' do
        it 'returns all the contacts in the default order' do
          expect(resolve_contacts(group)).to eq([contact_a, contact_b])
        end
      end

      context 'when a sort is provided' do
        it 'returns all the contacts in the correct order' do
          expect(resolve_contacts(group, { sort: 'EMAIL_DESC' })).to eq([contact_b, contact_a])
        end
      end

      context 'when a sort is provided needing offset_pagination' do
        it 'returns all the contacts in the correct order' do
          expect(resolve_contacts(group, { sort: 'ORGANIZATION_ASC' })).to eq([contact_a, contact_b])
        end
      end

      context 'when filtering for all states' do
        it 'returns all the contacts in the correct order' do
          expect(resolve_contacts(group, { state: 'all' })).to eq([contact_a, contact_b])
        end
      end

      context 'when search term is provided' do
        it 'returns the correct contacts' do
          expect(resolve_contacts(group, { search: "x@test.com" })).to contain_exactly(contact_b)
        end
      end

      context 'when state is provided' do
        it 'returns the correct contacts' do
          expect(resolve_contacts(group, { state: :inactive })).to contain_exactly(contact_a)
        end
      end

      context 'when ids are provided' do
        it 'returns the correct contacts' do
          expect(resolve_contacts(group, { ids: [contact_a.to_global_id] })).to contain_exactly(contact_a)
        end
      end
    end
  end

  def resolve_contacts(parent, args = {}, context = { current_user: user })
    resolve(described_class, obj: parent, args: args, ctx: context)
  end
end
