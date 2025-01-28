# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::InheritedVariablesResolver, feature_category: :ci_variables do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:project) { create(:project, group: subgroup) }
    let_it_be(:project_without_group) { create(:project) }
    let_it_be(:variable1) { create(:ci_group_variable, group: group, key: 'GROUP_VAR_A', created_at: 1.day.ago) }
    let_it_be(:variable2) { create(:ci_group_variable, group: subgroup, key: 'SUBGROUP_VAR_B') }

    let_it_be(:inherited_ci_variables) do
      [variable1, variable2]
    end

    let(:args) { {} }

    subject(:resolve_variables) { resolve(described_class, obj: obj, args: args, ctx: { current_user: user }) }

    context 'when project does not have a group' do
      let_it_be(:obj) { project_without_group }

      it 'returns an empty array' do
        expect(resolve_variables.items.to_a).to be_empty
      end
    end

    context 'when project belongs to a group' do
      let_it_be(:obj) { project }

      it 'returns variables from parent group and ancestors' do
        expect(resolve_variables.items.to_a).to match_array(inherited_ci_variables)
      end
    end

    describe 'sorting behaviour' do
      let_it_be(:obj) { project }

      context 'with sort by default (created_at descending)' do
        it 'returns variables ordered by created_at in descending order' do
          expect(resolve_variables.items.to_a).to eq([variable2, variable1])
        end
      end

      context 'with sort by created_at descending' do
        let(:args) { { sort: 'CREATED_DESC' } }

        it 'returns variables ordered by created_at in descending order' do
          expect(resolve_variables.items.to_a).to eq([variable2, variable1])
        end
      end

      context 'with sort by created_at ascending' do
        let(:args) { { sort: 'CREATED_ASC' } }

        it 'returns variables ordered by created_at in ascending order' do
          expect(resolve_variables.items.to_a).to eq([variable1, variable2])
        end
      end

      context 'with sort by key descending' do
        let(:args) { { sort: 'KEY_DESC' } }

        it 'returns variables ordered by key in descending order' do
          expect(resolve_variables.items.to_a).to eq([variable2, variable1])
        end
      end

      context 'with sort by key ascending' do
        let(:args) { { sort: 'KEY_ASC' } }

        it 'returns variables ordered by key in ascending order' do
          expect(resolve_variables.items.to_a).to eq([variable1, variable2])
        end
      end
    end
  end
end
