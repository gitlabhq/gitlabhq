# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Crm::OrganizationsFinder, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }

  describe '#execute' do
    subject { described_class.new(user, group: group).execute }

    context 'when customer relations feature is enabled for the group' do
      let_it_be(:root_group) { create(:group) }
      let_it_be(:group) { create(:group, parent: root_group) }

      let_it_be(:crm_organization_1) { create(:crm_organization, group: root_group) }
      let_it_be(:crm_organization_2) { create(:crm_organization, group: root_group) }

      context 'when user does not have permissions to see organizations in the group' do
        it 'returns an empty array' do
          expect(subject).to be_empty
        end
      end

      context 'when user is member of the root group' do
        before do
          root_group.add_developer(user)
        end

        context 'when feature flag is enabled' do
          it 'returns all group organizations' do
            expect(subject).to match_array([crm_organization_1, crm_organization_2])
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

    context 'when customer relations feature is disabled for the group' do
      let_it_be(:group) { create(:group, :crm_disabled) }
      let_it_be(:crm_organization) { create(:crm_organization, group: group) }

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
          :crm_organization,
          group: search_test_group,
          name: "DEF",
          description: "ghi_st",
          state: "inactive"
        )
      end

      let_it_be(:search_test_b) do
        create(
          :crm_organization,
          group: search_test_group,
          name: "ABC_st",
          description: "JKL",
          state: "active"
        )
      end

      before do
        search_test_group.add_developer(user)
      end

      context 'when search term is empty' do
        it 'returns all group organizations alphabetically ordered' do
          finder = described_class.new(user, group: search_test_group, search: "")
          expect(finder.execute).to eq([search_test_b, search_test_a])
        end
      end

      context 'when search term is not empty' do
        it 'searches for name' do
          finder = described_class.new(user, group: search_test_group, search: "aBc")
          expect(finder.execute).to match_array([search_test_b])
        end

        it 'searches for description' do
          finder = described_class.new(user, group: search_test_group, search: "ghI")
          expect(finder.execute).to match_array([search_test_a])
        end

        it 'searches for name and description' do
          finder = described_class.new(user, group: search_test_group, search: "_st")
          expect(finder.execute).to eq([search_test_b, search_test_a])
        end
      end

      context 'when searching for organizations state' do
        it 'returns only inactive organizations' do
          finder = described_class.new(user, group: search_test_group, state: :inactive)
          expect(finder.execute).to match_array([search_test_a])
        end

        it 'returns only active organizations' do
          finder = described_class.new(user, group: search_test_group, state: :active)
          expect(finder.execute).to match_array([search_test_b])
        end
      end

      context 'when searching for organizations ids' do
        it 'returns the expected organizations' do
          finder = described_class.new(user, group: search_test_group, ids: [search_test_a.id])

          expect(finder.execute).to match_array([search_test_a])
        end
      end
    end

    context 'when sorting' do
      let_it_be(:group) { create(:group) }

      let_it_be(:sort_test_a) do
        create(
          :crm_organization,
          group: group,
          name: "ABC",
          description: "1"
        )
      end

      let_it_be(:sort_test_b) do
        create(
          :crm_organization,
          group: group,
          name: "DEF",
          description: "2",
          default_rate: 10
        )
      end

      let_it_be(:sort_test_c) do
        create(
          :crm_organization,
          group: group,
          name: "GHI",
          default_rate: 20
        )
      end

      before do
        group.add_developer(user)
      end

      it 'returns the organiztions sorted by name in ascending order' do
        finder = described_class.new(user, group: group, sort: { field: 'name', direction: :asc })

        expect(finder.execute).to eq([sort_test_a, sort_test_b, sort_test_c])
      end

      it 'returns the organizations sorted by description in descending order' do
        finder = described_class.new(user, group: group, sort: { field: 'description', direction: :desc })

        expect(finder.execute).to eq([sort_test_b, sort_test_a, sort_test_c])
      end

      it 'returns the contacts sorted by default_rate in ascending order' do
        finder = described_class.new(user, group: group, sort: { field: 'default_rate', direction: :asc })

        expect(finder.execute).to eq([sort_test_b, sort_test_c, sort_test_a])
      end
    end

    context 'when a contact source, but not a root group' do
      let_it_be(:root_group) { create(:group, owners: user) }
      let_it_be(:group) do
        create(:group, parent: root_group).tap do |group|
          Group::CrmSettings.find_or_create_by!(group: group, source_group: group)
        end
      end

      let_it_be(:crm_organization_1) { create(:crm_organization, group: root_group) }
      let_it_be(:crm_organization_2) { create(:crm_organization, group: group) }

      it 'pulls organizations from the correct group' do
        expect(subject).to contain_exactly(crm_organization_2)
      end
    end
  end

  describe '.counts_by_state' do
    let_it_be(:group) { create(:group) }
    let_it_be(:active_crm_organizations) { create_list(:crm_organization, 3, group: group, state: :active) }
    let_it_be(:inactive_crm_organizations) { create_list(:crm_organization, 2, group: group, state: :inactive) }

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
