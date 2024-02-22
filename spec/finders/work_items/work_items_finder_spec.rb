# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::WorkItemsFinder, feature_category: :team_planning do
  include_context 'Issues or WorkItems Finder context', :work_item

  it_behaves_like 'issues or work items finder', :work_item, '{Issues|WorkItems}Finder#execute context'

  context 'when group parameter is present' do
    include_context '{Issues|WorkItems}Finder#execute context', :work_item

    let_it_be(:group_level_item) { create(:work_item, :group_level, namespace: group, author: user) }
    let_it_be(:group_level_confidential_item) do
      create(:work_item, :confidential, :group_level, namespace: group, author: user2)
    end

    let(:params) { { group_id: group } }
    let(:scope) { 'all' }

    it 'returns group level work items' do
      expect(items).to contain_exactly(item1, item5, group_level_item)
    end

    context 'when namespace_level_work_items is disabled' do
      before do
        stub_feature_flags(namespace_level_work_items: false)
      end

      it 'does not return group level work items' do
        expect(items).to contain_exactly(item1, item5)
      end
    end

    context 'when user has access to confidential items' do
      before do
        group.add_reporter(user)
      end

      it 'includes confidential group-level items' do
        expect(items).to contain_exactly(item1, item5, group_level_item, group_level_confidential_item)
      end

      context 'when namespace_level_work_items is disabled' do
        before do
          stub_feature_flags(namespace_level_work_items: false)
        end

        it 'only returns project-level items' do
          expect(items).to contain_exactly(item1, item5)
        end
      end
    end
  end
end
