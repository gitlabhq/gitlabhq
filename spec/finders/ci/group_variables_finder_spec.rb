# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::GroupVariablesFinder, feature_category: :ci_variables do
  subject(:finder) { described_class.new(project, sort_key).execute }

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project_with_subgroup) { create(:project, group: subgroup) }
  let_it_be(:project_without_group) { create(:project) }
  let_it_be(:variable1) { create(:ci_group_variable, group: group, key: 'GROUP_VAR_A', created_at: 1.day.ago) }
  let_it_be(:variable2) { create(:ci_group_variable, group: subgroup, key: 'SUBGROUP_VAR_B') }

  let_it_be(:inherited_ci_variables) do
    [variable1, variable2]
  end

  let(:sort_key) { nil }

  context 'when project does not have a group' do
    let_it_be(:project) { project_without_group }

    it 'returns an empty array' do
      expect(finder.to_a).to be_empty
    end
  end

  context 'when project belongs to a group' do
    let_it_be(:project) { project_with_subgroup }

    it 'returns variable from parent group and ancestors' do
      expect(finder.to_a).to match_array([variable1, variable2])
    end
  end

  describe 'sorting behaviour' do
    let_it_be(:project) { project_with_subgroup }

    context 'with sort by created_at descending' do
      let(:sort_key) { :created_desc }

      it 'returns variables ordered by created_at in descending order' do
        expect(finder.to_a).to eq([variable2, variable1])
      end
    end

    context 'with sort by created_at ascending' do
      let(:sort_key) { :created_asc }

      it 'returns variables ordered by created_at in ascending order' do
        expect(finder.to_a).to eq([variable1, variable2])
      end
    end

    context 'with sort by key descending' do
      let(:sort_key) { :key_desc }

      it 'returns variables ordered by key in descending order' do
        expect(finder.to_a).to eq([variable2, variable1])
      end
    end

    context 'with sort by key ascending' do
      let(:sort_key) { :key_asc }

      it 'returns variables ordered by key in ascending order' do
        expect(finder.to_a).to eq([variable1, variable2])
      end
    end
  end
end
