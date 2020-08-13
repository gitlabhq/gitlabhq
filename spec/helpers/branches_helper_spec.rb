# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BranchesHelper do
  describe '#access_levels_data' do
    subject { helper.access_levels_data(access_levels) }

    context 'when access_levels is nil' do
      let(:access_levels) { nil }

      it { is_expected.to be_empty }
    end

    context 'when access levels are provided' do
      let(:protected_branch) { create(:protected_branch, :developers_can_merge, :maintainers_can_push) }

      let(:merge_level) { protected_branch.merge_access_levels.first }
      let(:push_level) { protected_branch.push_access_levels.first }
      let(:access_levels) { [merge_level, push_level] }

      it 'returns the correct array' do
        expected_array = [
          { id: merge_level.id, type: :role, access_level: Gitlab::Access::DEVELOPER },
          { id: push_level.id, type: :role, access_level: Gitlab::Access::MAINTAINER }
        ]

        expect(subject).to eq(expected_array)
      end
    end
  end
end
