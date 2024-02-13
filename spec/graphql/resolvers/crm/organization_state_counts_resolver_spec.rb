# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Crm::OrganizationStateCountsResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before_all do
    create(:crm_organization, group: group, name: "ABC Corp")
    create(:crm_organization, group: group, name: "123 Corp", state: 'inactive')
    create_list(:crm_organization, 3, group: group)
    create_list(:crm_organization, 2, group: group, state: 'inactive')
  end

  describe '#resolve' do
    context 'with unauthorized user' do
      it 'does not raise an error and returns nil' do
        expect { resolve_counts(group) }.not_to raise_error
        expect(resolve_counts(group)).to be_nil
      end
    end

    context 'with authorized user' do
      before do
        group.add_reporter(user)
      end

      context 'without parent' do
        it 'returns nil' do
          expect(resolve_counts(nil)).to be_nil
        end
      end

      context 'with a group' do
        context 'when no filter is provided' do
          it 'returns the count of all crm_organizations' do
            counts = resolve_counts(group)
            expect(counts['active']).to eq(4)
            expect(counts['inactive']).to eq(3)
          end
        end

        context 'when search term is provided' do
          it 'returns the correct counts' do
            counts = resolve_counts(group, { search: "Corp" })

            expect(counts['active']).to eq(1)
            expect(counts['inactive']).to eq(1)
          end
        end
      end
    end
  end

  def resolve_counts(parent, args = {}, context = { current_user: user })
    resolve(described_class, obj: parent, args: args, ctx: context)
  end
end
