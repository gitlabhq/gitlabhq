# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Namespaces::WorkItemsResolver, feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project_namespace) { create(:project_namespace) }
  let_it_be(:current_user)      { create(:user, developer_of: project_namespace.project) }

  def resolve_items(obj, args = {})
    resolve(described_class, obj: obj, args: args, ctx: { current_user: current_user }, arg_style: :internal)
  end

  context 'with a project namespace' do
    let_it_be(:project_work_item_1) { create(:work_item, project: project_namespace.project) }
    let_it_be(:project_work_item_2) { create(:work_item, project: project_namespace.project) }

    it 'returns work items at the project level' do
      expect(resolve_items(project_namespace, {})).to contain_exactly(project_work_item_1, project_work_item_2)
    end

    it 'filters using project level args' do
      expect(resolve_items(project_namespace, { iid: project_work_item_1.iid })).to contain_exactly(project_work_item_1)
    end

    it 'filters out group level args' do
      # Expect that the include_ancestors param has been filtered out
      expect(::WorkItems::WorkItemsFinder).to receive(:new).with(current_user, {}).and_call_original

      resolve_items(project_namespace, { include_ancestors: true })
    end

    context 'with include_archived filtering' do
      let_it_be(:archived_project) { create(:project, :archived, developers: current_user) }
      let_it_be(:work_item_archived_project) { create(:work_item, project: archived_project) }

      it 'is ignored for project namespaces' do
        items = resolve_items(archived_project.project_namespace, { include_archived: false })
        expect(items).to contain_exactly(work_item_archived_project)
      end
    end
  end

  context 'with a group namespace' do
    let_it_be(:group) { create(:group, developers: current_user) }

    context 'with include_archived filtering' do
      let_it_be(:project) { create(:project, group: group) }
      let_it_be(:archived_project) { create(:project, :archived, group: group) }

      let_it_be(:work_item) { create(:work_item, project: project) }
      let_it_be(:work_item_archived_project) { create(:work_item, project: archived_project) }

      it 'does not include work items from archived projects by default' do
        items = resolve_items(group, { include_descendants: true })
        expect(items).to contain_exactly(work_item)
      end

      it 'does not include work items from archived projects when include_archived is false' do
        items = resolve_items(group, { include_archived: false, include_descendants: true })
        expect(items).to contain_exactly(work_item)
      end

      it 'includes work items from archived projects when include_archived is true' do
        items = resolve_items(group, { include_archived: true, include_descendants: true })
        expect(items).to contain_exactly(work_item, work_item_archived_project)
      end
    end
  end

  context 'with a user namespace' do
    let_it_be(:user_namespace) { create(:user_namespace) }

    it 'returns nil' do
      expect(resolve_items(user_namespace)).to be_nil
    end
  end
end
