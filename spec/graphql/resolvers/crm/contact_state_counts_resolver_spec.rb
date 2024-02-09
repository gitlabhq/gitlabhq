# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Crm::ContactStateCountsResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before_all do
    create(:contact, group: group, email: "x@test.com")
    create(:contact, group: group, email: "y@test.com", state: 'inactive')
    create_list(:contact, 3, group: group)
    create_list(:contact, 2, group: group, state: 'inactive')
  end

  describe '#resolve' do
    context 'with unauthorized user' do
      it 'does not raise an error and returns no counts' do
        expect { resolve_counts(group) }.not_to raise_error
        expect(resolve_counts(group).all).to be(0)
      end
    end

    context 'with authorized user' do
      before do
        group.add_reporter(user)
      end

      context 'without parent' do
        it 'returns no counts' do
          expect(resolve_counts(nil).all).to be(0)
        end
      end

      context 'with a group' do
        context 'when no filter is provided' do
          it 'returns the count of all contacts' do
            counts = resolve_counts(group)
            expect(counts.all).to eq(7)
            expect(counts.active).to eq(4)
            expect(counts.inactive).to eq(3)
          end
        end

        context 'when search term is provided' do
          it 'returns the correct counts' do
            counts = resolve_counts(group, { search: "@test.com" })

            expect(counts.all).to be(2)
            expect(counts.active).to be(1)
            expect(counts.inactive).to be(1)
          end
        end
      end
    end
  end

  def resolve_counts(parent, args = {}, context = { current_user: user })
    resolve(described_class, obj: parent, args: args, ctx: context)
  end
end
