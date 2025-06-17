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
  end

  context 'with a user namespace' do
    let_it_be(:user_namespace) { create(:user_namespace) }

    it 'returns nil' do
      expect(resolve_items(user_namespace)).to be_nil
    end
  end
end
