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

    context 'when an access level tied to a deploy key is provided' do
      let!(:protected_branch) { create(:protected_branch, :no_one_can_push) }
      let!(:deploy_key) { create(:deploy_key, deploy_keys_projects: [create(:deploy_keys_project, :write_access, project: protected_branch.project)]) }

      let(:push_level) { protected_branch.push_access_levels.first }
      let(:deploy_key_push_level) { create(:protected_branch_push_access_level, protected_branch: protected_branch, deploy_key: deploy_key) }
      let(:access_levels) { [push_level, deploy_key_push_level] }

      it 'returns the correct array' do
        expected_array = [
          { id: push_level.id, type: :role, access_level: Gitlab::Access::NO_ACCESS },
          { id: deploy_key_push_level.id, type: :deploy_key, deploy_key_id: deploy_key.id }
        ]

        expect(subject).to eq(expected_array)
      end
    end
  end
end
