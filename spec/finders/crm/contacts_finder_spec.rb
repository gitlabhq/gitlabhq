# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Crm::ContactsFinder, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }

  describe '#execute' do
    subject { described_class.new(user, group: group).execute }

    context 'when customer relations feature is enabled for the group' do
      let_it_be(:root_group) { create(:group) }
      let_it_be(:group) { create(:group, parent: root_group) }

      let_it_be(:contact_1) { create(:contact, group: root_group) }
      let_it_be(:contact_2) { create(:contact, group: root_group) }

      context 'when user does not have permissions to see contacts in the group' do
        it 'returns an empty array' do
          expect(subject).to be_empty
        end
      end

      context 'when user is member of the root group' do
        before do
          root_group.add_developer(user)
        end

        context 'when feature flag is enabled' do
          it 'returns all group contacts' do
            expect(subject).to match_array([contact_1, contact_2])
          end
        end
      end

      context 'when user is member of the sub group' do
        before do
          group.add_developer(user)
        end

        it 'returns an empty array' do
          expect(subject).to be_empty
        end
      end
    end

    context 'when crm feature is disabled for the group' do
      let_it_be(:group) { create(:group, :crm_disabled) }
      let_it_be(:contact) { create(:contact, group: group) }

      before do
        group.add_developer(user)
      end

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end

    context 'with search informations' do
      let_it_be(:search_test_group) { create(:group) }

      let_it_be(:search_test_a) do
        create(
          :contact,
          group: search_test_group,
          first_name: "ABC",
          last_name: "DEF",
          email: "ghi@test.com",
          description: "LMNO",
          state: "inactive"
        )
      end

      let_it_be(:search_test_b) do
        create(
          :contact,
          group: search_test_group,
          first_name: "PQR",
          last_name: "STU",
          email: "vwx@test.com",
          description: "YZ",
          state: "active"
        )
      end

      before do
        search_test_group.add_developer(user)
      end

      context 'when search term is empty' do
        it 'returns all group contacts alphabetically ordered' do
          finder = described_class.new(user, group: search_test_group, search: "")
          expect(finder.execute).to eq([search_test_a, search_test_b])
        end
      end

      context 'when search term is not empty' do
        it 'searches for first name ignoring casing' do
          finder = described_class.new(user, group: search_test_group, search: "aBc")
          expect(finder.execute).to match_array([search_test_a])
        end

        it 'searches for last name ignoring casing' do
          finder = described_class.new(user, group: search_test_group, search: "StU")
          expect(finder.execute).to match_array([search_test_b])
        end

        it 'searches for email' do
          finder = described_class.new(user, group: search_test_group, search: "ghi")
          expect(finder.execute).to match_array([search_test_a])
        end

        it 'searches for description ignoring casing' do
          finder = described_class.new(user, group: search_test_group, search: "Yz")
          expect(finder.execute).to match_array([search_test_b])
        end

        it 'fuzzy searches for email and last name' do
          finder = described_class.new(user, group: search_test_group, search: "s")
          expect(finder.execute).to match_array([search_test_a, search_test_b])
        end
      end

      context 'when searching for contacts state' do
        it 'returns only inactive contacts' do
          finder = described_class.new(user, group: search_test_group, state: :inactive)
          expect(finder.execute).to match_array([search_test_a])
        end

        it 'returns only active contacts' do
          finder = described_class.new(user, group: search_test_group, state: :active)
          expect(finder.execute).to match_array([search_test_b])
        end
      end

      context 'when searching for contacts ids' do
        it 'returns the expected contacts' do
          finder = described_class.new(user, group: search_test_group, ids: [search_test_b.id])

          expect(finder.execute).to match_array([search_test_b])
        end
      end

      context 'when sorting' do
        let_it_be(:search_test_c) do
          create(
            :contact,
            group: search_test_group,
            email: "a@test.com",
            organization: create(:crm_organization, name: "Company Z")
          )
        end

        let_it_be(:search_test_d) do
          create(
            :contact,
            group: search_test_group,
            email: "b@test.com",
            organization: create(:crm_organization, name: "Company A")
          )
        end

        it 'returns the contacts sorted by email in ascending order' do
          finder = described_class.new(user, group: search_test_group, sort: { field: 'email', direction: :asc })

          expect(finder.execute).to eq([search_test_c, search_test_d, search_test_a, search_test_b])
        end

        it 'returns the contacts sorted by description in ascending order' do
          finder = described_class.new(user, group: search_test_group, sort: { field: 'description', direction: :desc })

          results = finder.execute

          expect(results[0]).to eq(search_test_b)
          expect(results[1]).to eq(search_test_a)
        end

        it 'returns the contacts sorted by organization in ascending order' do
          finder = described_class.new(user, group: search_test_group, sort: { field: 'organization', direction: :asc })

          results = finder.execute

          expect(results[0]).to eq(search_test_d)
          expect(results[1]).to eq(search_test_c)
        end
      end
    end
  end

  describe '.counts_by_state' do
    let_it_be(:group) { create(:group) }
    let_it_be(:active_contacts) { create_list(:contact, 3, group: group, state: :active) }
    let_it_be(:inactive_contacts) { create_list(:contact, 2, group: group, state: :inactive) }

    before do
      group.add_developer(user)
    end

    it 'returns correct counts' do
      counts = described_class.counts_by_state(user, group: group)

      expect(counts["active"]).to eq(3)
      expect(counts["inactive"]).to eq(2)
    end
  end
end
