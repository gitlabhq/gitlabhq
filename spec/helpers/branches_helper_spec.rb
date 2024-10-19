# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BranchesHelper, feature_category: :source_code_management do
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
      let!(:user) { create(:user, guest_of: protected_branch.project) }
      let!(:deploy_key) { create(:deploy_key, user: user, write_access_to: protected_branch.project) }

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

  describe '#merge_request_status' do
    subject { helper.merge_request_status(merge_request) }

    let(:merge_request) { build(:merge_request, title: title) }
    let(:title) { 'Test MR' }

    context 'when merge request is missing' do
      let(:merge_request) { nil }

      it { is_expected.to be_nil }
    end

    context 'when merge request is closed' do
      before do
        merge_request.close
      end

      it { is_expected.to eq(icon: 'merge-request-close', title: "Closed - #{title}", variant: :danger) }
    end

    context 'when merge request is open' do
      it { is_expected.to eq(icon: 'merge-request', title: "Open - #{title}", variant: :success) }
    end

    context 'when merge request is locked' do
      let(:merge_request) { build(:merge_request, :locked, title: title) }

      it { is_expected.to eq(icon: 'merge-request', title: "Open - #{title}", variant: :success) }
    end

    context 'when merge request is draft' do
      let(:title) { 'Draft: Test MR' }

      it { is_expected.to eq(icon: 'merge-request', title: "Open - #{title}", variant: :warning) }
    end

    context 'when merge request is merged' do
      let(:merge_request) { build(:merge_request, :merged, title: title) }

      it { is_expected.to eq(icon: 'merge', title: "Merged - #{title}", variant: :info) }
    end

    context 'when merge request status is unsupported' do
      let(:merge_request) { build(:merge_request, state_id: -1) }

      it { is_expected.to be_nil }
    end
  end
end
