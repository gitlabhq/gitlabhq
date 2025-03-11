# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::WorkItems::Widgets::StatusResolver, feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:task_type) { create(:work_item_type, :task) }
  let_it_be(:widget_definition) do
    create(:widget_definition, widget_type: :status, work_item_type: task_type, name: 'TesT Widget')
  end

  shared_examples 'does not return system defined statuses' do
    it 'returns an empty array' do
      expect(resolve_statuses&.items).to eq([])
    end
  end

  describe '#resolve' do
    let(:resource_parent) { group }

    context 'with group' do
      it_behaves_like 'does not return system defined statuses'
    end

    context 'with project' do
      let(:resource_parent) { project }

      it_behaves_like 'does not return system defined statuses'
    end

    context 'with unsupported namespace' do
      let(:resource_parent) { current_user.namespace }

      it_behaves_like 'does not return system defined statuses'
    end

    context 'with work_item_status feature flag disabled' do
      before do
        stub_feature_flags(work_item_status: false)
      end

      it_behaves_like 'does not return system defined statuses'
    end
  end

  def resolve_statuses(args = {}, context = { current_user: current_user, resource_parent: resource_parent })
    resolve(described_class, obj: widget_definition, args: args, ctx: context)
  end
end
