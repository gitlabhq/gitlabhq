# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::WorkItemsFinder, feature_category: :team_planning do
  include_context 'Issues or WorkItems Finder context', :work_item

  it_behaves_like 'issues or work items finder', :work_item, '{Issues|WorkItems}Finder#execute context'

  context 'with group parameter' do
    include_context '{Issues|WorkItems}Finder#execute context', :work_item

    it_behaves_like 'work items finder group parameter'
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
