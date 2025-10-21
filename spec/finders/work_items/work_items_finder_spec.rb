# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::WorkItemsFinder, feature_category: :team_planning do
  include_context 'Issues or WorkItems Finder context', :work_item

  it_behaves_like 'issues or work items finder', :work_item, '{Issues|WorkItems}Finder#execute context'

  context 'with group parameter' do
    include_context '{Issues|WorkItems}Finder#execute context', :work_item

    it_behaves_like 'work items finder group parameter', expect_group_items: false
  end

  context 'with namespace_traversal_ids_filtering' do
    include_context '{Issues|WorkItems}Finder#execute context', :work_item

    let_it_be(:group_work_item) { create(:work_item, :group_level, namespace: group, author: user) }
    let_it_be(:group_project_work_item) { create(:work_item, project: project1, author: user) }

    let_it_be(:subgroup_work_item) { create(:work_item, :group_level, namespace: subgroup, author: user) }

    let(:params) { { group_id: group, include_descendants: true } }
    let(:scope) { 'all' }

    before do
      group.add_developer(user)
    end

    it 'only returns project level work_items' do
      expect(items).to contain_exactly(item1, item4, item5, group_project_work_item)
    end

    it 'generates query with condition to filter out work_items without project_id' do
      result_sql = items.to_sql
      expect(result_sql).to include('"issues"."project_id" IS NOT NULL')
    end

    it 'generates query with namespace_traversal_id filtering' do
      result_sql = items.to_sql

      expect(result_sql).to include("namespace_traversal_ids[1] = #{group.id}")
                            .or(
                              include('"issues"."namespace_traversal_ids" >=')
                              .and(include('"issues"."namespace_traversal_ids" <'))
                            )
    end
  end

  context 'with start and end date filtering' do
    include_context '{Issues|WorkItems}Finder#execute context', :work_item

    let_it_be(:work_item1) { create(:work_item, :issue, project: project1) }
    let_it_be(:work_item2) { create(:work_item, :issue, project: project1) }

    let(:scope) { 'all' }
    let(:params) { { start_date: '2020-08-12', end_date: '2020-08-14', project_id: project1.id } }

    before do
      group.add_developer(user)
    end

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

  context 'when using work_item_parent_ids filter' do
    include_context '{Issues|WorkItems}Finder#execute context', :work_item

    let(:scope) { 'all' }

    context 'when user has access to child item' do
      let_it_be(:child_item1) { create(:work_item, project: project1) }
      let_it_be(:parent_item1) { create(:work_item, :epic, project: project1) }

      let(:params) { { work_item_parent_ids: [parent_item1.id] } }

      before do
        create(:parent_link, work_item_parent: parent_item1, work_item: child_item1)
      end

      it 'returns corresponding child work items' do
        expect(items).to contain_exactly(child_item1)
      end
    end

    context 'when filtering by parent item from different project' do
      let_it_be(:another_project) { create(:project) }
      let_it_be(:child_item2) { create(:work_item, project: project1) }
      let_it_be(:parent_item2) { create(:work_item, :epic, project: another_project) }

      let(:params) { { work_item_parent_ids: [parent_item2.id] } }

      before do
        create(:parent_link, work_item_parent: parent_item2, work_item: child_item2)
      end

      it 'returns corresponding child work items' do
        expect(items).to contain_exactly(child_item2)
      end
    end

    context 'when filtering by multiple parent items' do
      let_it_be(:child_item3) { create(:work_item, project: project1) }
      let_it_be(:child_item4) { create(:work_item, project: project1) }

      let_it_be(:parent_item3) { create(:work_item, :epic, project: project1) }
      let_it_be(:parent_item4) { create(:work_item, :epic, project: project1) }

      let(:params) { { work_item_parent_ids: [parent_item3.id, parent_item4.id] } }

      before do
        create(:parent_link, work_item_parent: parent_item3, work_item: child_item3)
        create(:parent_link, work_item_parent: parent_item4, work_item: child_item4)
      end

      it 'returns corresponding child work items' do
        expect(items).to contain_exactly(child_item3, child_item4)
      end
    end

    context 'when user does not have access to child items' do
      let_it_be(:confidential_work_item) { create(:work_item, confidential: true, project: project1) }
      let_it_be(:parent_item5) { create(:work_item, :epic, confidential: true, project: project1) }

      let(:search_user) { user2 }
      let(:params) { { work_item_parent_ids: [parent_item5.id] } }

      before do
        create(:parent_link, work_item_parent: parent_item5, work_item: confidential_work_item)
      end

      it 'does not return those items' do
        expect(items).to be_empty
      end
    end

    context 'when user does not have access to child and parent items' do
      let_it_be(:private_project) { create(:project, :private) }
      let_it_be(:private_work_item) { create(:work_item, project: private_project) }
      let_it_be(:private_parent_item) { create(:work_item, :epic, project: private_project) }

      let(:search_user) { user2 }
      let(:params) { { work_item_parent_ids: [private_parent_item.id] } }

      before do
        create(:parent_link, work_item_parent: private_parent_item, work_item: private_work_item)
      end

      it 'does not return those items' do
        expect(items).to be_empty
      end
    end

    context 'when using include_descendant_work_items filter' do
      let_it_be(:parent_item) { create(:work_item, :epic) }
      let_it_be(:child_item_1) { create(:work_item, :issue, project: project1) }
      let_it_be(:child_item_2) { create(:work_item, :task, project: project1) }

      let(:params) { { work_item_parent_ids: [parent_item.id], include_descendant_work_items: true } }

      before do
        create(:parent_link, work_item_parent: parent_item, work_item: child_item_1)
        create(:parent_link, work_item_parent: child_item_1, work_item: child_item_2)
      end

      it 'includes descendant work items regardless of the work item types' do
        expect(items).to include(child_item_1, child_item_2)
      end
    end
  end

  context 'when filtering by NOT parent_ids' do
    include_context '{Issues|WorkItems}Finder#execute context', :work_item

    let_it_be(:work_item_without_parent) { create(:work_item, :issue, project: project1) }
    let_it_be(:work_item_with_parent) { create(:work_item, :task, project: project1) }

    let_it_be(:unrelated_work_item) { create(:work_item, :issue, project: project1) }
    let_it_be(:unrelated_work_item_with_parent) { create(:work_item, :task, project: project1) }

    let(:scope) { 'all' }
    let(:params) { { not: { work_item_parent_ids: [work_item_without_parent.id] } } }

    before do
      create(:parent_link, work_item_parent: work_item_without_parent, work_item: work_item_with_parent)
      create(:parent_link, work_item_parent: unrelated_work_item, work_item: unrelated_work_item_with_parent)
    end

    it 'does not include items with the specified parent' do
      expect(items).not_to include(work_item_with_parent)
      expect(items).to include(work_item_without_parent, unrelated_work_item, unrelated_work_item_with_parent)
    end
  end

  context 'when using parent_wildcard_id filter' do
    include_context '{Issues|WorkItems}Finder#execute context', :work_item

    let_it_be(:work_item_without_parent) { create(:work_item, :issue, project: project1) }
    let_it_be(:work_item_with_parent) { create(:work_item, :task, project: project1) }
    let(:scope) { 'all' }

    before do
      create(:parent_link, work_item_parent: work_item_without_parent, work_item: work_item_with_parent)
    end

    context 'with ANY wildcard' do
      let(:params) { { parent_wildcard_id: 'ANY' } }

      it 'returns work items with any parent' do
        filtered_items = items

        expect(filtered_items).to include(work_item_with_parent)
        expect(filtered_items).not_to include(work_item_without_parent)
      end
    end

    context 'with NONE wildcard' do
      let(:params) { { parent_wildcard_id: 'NONE' } }

      it 'returns work items with no parent' do
        filtered_items = items

        expect(filtered_items).to include(work_item_without_parent)
        expect(filtered_items).not_to include(work_item_with_parent)
      end
    end
  end

  context 'when filtering by ids' do
    include_context '{Issues|WorkItems}Finder#execute context', :work_item

    let(:params) { { ids: [item1.id, item3.id] } }
    let(:scope) { 'all' }

    it 'returns only issues with the specified ids' do
      expect(items).to contain_exactly(item1, item3)
    end

    context 'when ids list is empty' do
      let(:params) { { ids: [] } }

      it 'does not apply the ID filter' do
        expect(items).to contain_exactly(item1, item2, item3, item4, item5)
      end
    end

    context 'when ids contain a non-existing id' do
      let(:params) { { ids: [non_existing_record_id] } }

      it 'returns no issues' do
        expect(items).to be_empty
      end
    end
  end
end
