# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::WorkItems::TypesResolver, feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, developers: current_user) }
  let_it_be(:project) { create(:project, group: group) }

  let(:args) { {} }

  let(:result) { resolve(described_class, obj: object, args: args) }

  subject(:types_list) { result.map(&:base_type) }

  describe '#resolve' do
    context 'when parent is a group' do
      let(:object) { group }

      it_behaves_like 'lists all work item type values'

      it_behaves_like 'filtering work item types by existing name' do
        let(:name) { 'epic' }
        let(:args) { { name: name } }
      end

      it_behaves_like 'allowed work item types for a group' do
        let(:args) { { only_available: true } }
      end
    end

    context 'when parent is a project' do
      let(:object) { project }

      it_behaves_like 'lists all work item type values'

      it_behaves_like 'filtering work item types by existing name' do
        let(:name) { 'issue' }
        let(:args) { { name: name } }
      end

      it_behaves_like 'allowed work item types for a project' do
        let(:args) { { only_available: true } }
      end
    end
  end
end
