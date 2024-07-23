# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::WorkItems::TypesResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group)        { create(:group, developers: current_user) }
  let_it_be(:project)      { create(:project, group: group) }

  shared_examples 'a work item type resolver' do
    let(:args) { {} }

    subject(:result) { resolve(described_class, obj: object, args: args) }

    it 'returns all work item types' do
      expect(result.to_a).to match(WorkItems::Type.order_by_name_asc)
    end

    context 'when filtering by type name' do
      let(:args) { { name: 'TASK' } }

      it 'returns type with the given name' do
        expect(result.to_a).to contain_exactly(WorkItems::Type.default_by_type(:task))
      end
    end
  end

  describe '#resolve' do
    context 'when parent is a group' do
      let(:object) { group }

      it_behaves_like 'a work item type resolver'
    end

    context 'when parent is a project' do
      let(:object) { project }

      it_behaves_like 'a work item type resolver'
    end
  end
end
