# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::WorkItemsFinder, feature_category: :team_planning do
  include_context 'Issues or WorkItems Finder context', :work_item

  it_behaves_like 'issues or work items finder', :work_item, '{Issues|WorkItems}Finder#execute context'

  context 'when group parameter is present' do
    include_context '{Issues|WorkItems}Finder#execute context', :work_item

    let_it_be(:group_work_item) { create(:work_item, :group_level, namespace: group, author: user) }
    let_it_be(:group_confidential_work_item) do
      create(:work_item, :confidential, :group_level, namespace: group, author: user2)
    end

    let_it_be(:subgroup_work_item) { create(:work_item, :group_level, namespace: subgroup, author: user) }
    let_it_be(:subgroup_confidential_work_item) do
      create(:work_item, :confidential, :group_level, namespace: subgroup, author: user2)
    end

    let_it_be(:subgroup2) { create(:group, :private, parent: group) }
    let_it_be(:subgroup2_work_item) { create(:work_item, :group_level, namespace: subgroup2, author: user) }
    let_it_be(:subgroup2_confidential_work_item) do
      create(:work_item, :confidential, :group_level, namespace: subgroup2, author: user2)
    end

    let(:params) { { group_id: group } }
    let(:scope) { 'all' }

    context 'when namespace_level_work_items is disabled' do
      before do
        stub_feature_flags(namespace_level_work_items: false)
      end

      it 'does not return group level work items' do
        expect(items).to contain_exactly(item1, item5)
      end
    end

    it 'returns group level work items' do
      expect(items).to contain_exactly(group_work_item)
    end

    context 'when user has access to confidential items' do
      before do
        group.add_reporter(user)
      end

      it 'includes confidential group-level items' do
        expect(items).to contain_exactly(group_work_item, group_confidential_work_item)
      end
    end

    context 'when include_descendants is true' do
      before do
        params[:include_descendants] = true
      end

      context 'when user does not have access to all subgroups' do
        it 'includes work items from subgroups and child projects with access' do
          expect(items).to contain_exactly(group_work_item, subgroup_work_item, item1, item4, item5)
        end
      end

      context 'when user has read access to all subgroups' do
        before_all do
          subgroup2.add_guest(user)
        end

        it 'includes work items from subgroups and child projects with access' do
          expect(items).to contain_exactly(
            group_work_item,
            subgroup_work_item,
            subgroup2_work_item,
            item1,
            item4,
            item5
          )
        end
      end

      context 'when user can access all confidential items' do
        before_all do
          group.add_reporter(user)
        end

        it 'includes confidential items from subgroups and child projects' do
          expect(items).to contain_exactly(
            group_work_item,
            group_confidential_work_item,
            subgroup_work_item,
            subgroup_confidential_work_item,
            subgroup2_work_item,
            subgroup2_confidential_work_item,
            item1,
            item4,
            item5
          )
        end
      end

      context 'when user can access confidential issues of certain subgroups only' do
        before_all do
          subgroup2.add_reporter(user)
        end

        it 'includes confidential items from subgroups and child projects with access' do
          expect(items).to contain_exactly(
            group_work_item,
            subgroup_work_item,
            subgroup2_work_item,
            subgroup2_confidential_work_item,
            item1,
            item4,
            item5
          )
        end
      end

      context 'when exclude_projects is true' do
        before do
          params[:exclude_projects] = true
        end

        it 'does not include work items from projects' do
          expect(items).to contain_exactly(group_work_item, subgroup_work_item)
        end
      end
    end

    context 'when include_ancestors is true' do
      let(:params) { { group_id: subgroup, include_ancestors: true } }

      it 'includes work items from ancestor groups' do
        expect(items).to contain_exactly(group_work_item, subgroup_work_item)
      end
    end

    context 'when both include_descendants and include_ancestors are true' do
      let_it_be(:sub_subgroup) { create(:group, parent: subgroup) }
      let_it_be(:sub_subgroup_work_item) { create(:work_item, :group_level, namespace: sub_subgroup, author: user) }

      let(:params) { { group_id: subgroup, include_descendants: true, include_ancestors: true } }

      it 'includes work items from ancestor groups, subgroups, and child projects' do
        expect(items).to contain_exactly(group_work_item, subgroup_work_item, sub_subgroup_work_item, item4)
      end
    end
  end

  context 'with start and end date filtering' do
    include_context '{Issues|WorkItems}Finder#execute context', :work_item

    let(:scope) { 'all' }
    let(:params) { { start_date: '2020-08-12', end_date: '2020-08-14', group_id: group.id } }

    context 'when namespace level work items are disabled' do
      before do
        stub_feature_flags(namespace_level_work_items: false)
        group.add_developer(user)
      end

      let_it_be(:work_item1) { create(:work_item, project: project1) }
      let_it_be(:work_item2) { create(:work_item, project: project1) }

      let_it_be(:date_source1) do
        create(:work_items_dates_source, work_item: work_item1, start_date: '2020-08-13', due_date: '2020-08-15')
      end

      let_it_be(:date_source2) do
        create(:work_items_dates_source, work_item: work_item2, start_date: '2020-08-16', due_date: '2020-08-20')
      end

      it 'does not attempt to filter by timeframe' do
        expect(items).to include(work_item1, work_item2)
      end
    end

    context 'when namespace level work items are enabled' do
      before do
        stub_feature_flags(namespace_level_work_items: true, work_item_epics: true)
        group.add_developer(user)
      end

      let_it_be(:work_item1) { create(:work_item, :group_level, :epic, namespace: group) }
      let_it_be(:work_item2) { create(:work_item, :group_level, :epic, namespace: group) }

      it 'does not return work items without a dates source' do
        expect(items).to be_empty
      end

      context 'when work item start and due dates are both present' do
        let_it_be(:date_source1) do
          create(:work_items_dates_source, work_item: work_item1, start_date: '2020-08-13', due_date: '2020-08-15')
        end

        let_it_be(:date_source2) do
          create(:work_items_dates_source, work_item: work_item2, start_date: '2020-08-16', due_date: '2020-08-20')
        end

        it 'returns only work items within timeframe' do
          expect(items).to contain_exactly(work_item1)
        end
      end

      context 'when only start date or due date is present' do
        let_it_be(:date_source_only_start) do
          create(:work_items_dates_source, work_item: work_item1, start_date: '2020-08-12', due_date: nil)
        end

        let_it_be(:date_source_only_due) do
          create(:work_items_dates_source, work_item: work_item2, start_date: nil, due_date: '2020-08-14')
        end

        it 'returns only work items within timeframe' do
          expect(items).to contain_exactly(work_item1, work_item2)
        end
      end
    end
  end
end
