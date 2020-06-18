# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranchesFinder do
  let(:project) { create(:project) }
  let!(:protected_branch) { create(:protected_branch, project: project) }
  let!(:another_protected_branch) { create(:protected_branch, project: project) }
  let!(:other_protected_branch) { create(:protected_branch) }
  let(:params) { {} }

  describe '#execute' do
    subject { described_class.new(project, params).execute }

    it 'returns all protected branches of project by default' do
      expect(subject).to match_array([protected_branch, another_protected_branch])
    end

    context 'when search param is present' do
      let(:params) { { search: protected_branch.name } }

      it 'filters by search param' do
        expect(subject).to eq([protected_branch])
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
end
