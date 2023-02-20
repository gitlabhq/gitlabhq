# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranchesFinder do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }

  let!(:project_protected_branch) { create(:protected_branch, project: project) }
  let!(:another_project_protected_branch) { create(:protected_branch, project: project) }
  let!(:group_protected_branch) { create(:protected_branch, project: nil, group: group) }
  let!(:another_group_protected_branch) { create(:protected_branch, project: nil, group: group) }
  let!(:other_protected_branch) { create(:protected_branch) }

  let(:params) { {} }

  subject { described_class.new(entity, params).execute }

  describe '#execute' do
    shared_examples 'execute by entity' do
      it 'returns all protected branches of project by default' do
        expect(subject).to match_array(expected_branches)
      end

      context 'when search param is present' do
        let(:params) { { search: group_protected_branch.name } }

        it 'filters by search param' do
          expect(subject).to eq([group_protected_branch])
        end
      end

      context 'when there are more protected branches than the limit' do
        before do
          stub_const("#{described_class}::LIMIT", 1)
        end

        it 'returns limited protected branches of project' do
          expect(subject.count).to eq(1)
        end
      end
    end

    it_behaves_like 'execute by entity' do
      let(:entity) { project }
      let(:expected_branches) do
        [
          project_protected_branch, another_project_protected_branch,
          group_protected_branch, another_group_protected_branch
        ]
      end
    end

    it_behaves_like 'execute by entity' do
      let(:entity) { group }
      let(:expected_branches) { [group_protected_branch, another_group_protected_branch] }
    end
  end
end
