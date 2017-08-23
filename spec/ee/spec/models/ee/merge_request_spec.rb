require 'spec_helper'

describe MergeRequest do
  using RSpec::Parameterized::TableSyntax

  let(:project) { create(:project, :repository) }

  subject(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  describe 'associations' do
    it { is_expected.to have_many(:approvals).dependent(:delete_all) }
    it { is_expected.to have_many(:approvers).dependent(:delete_all) }
    it { is_expected.to have_many(:approver_groups).dependent(:delete_all) }
  end

  describe '#should_be_rebased?' do
    subject { merge_request.should_be_rebased? }

    context 'project forbids rebase' do
      it { is_expected.to be_falsy }
    end

    context 'project allows rebase' do
      let(:project) { create(:project, :repository, merge_requests_rebase_enabled: true) }

      it 'returns false when the project feature is unavailable' do
        expect(merge_request.target_project).to receive(:feature_available?).with(:merge_request_rebase).at_least(:once).and_return(false)

        is_expected.to be_falsy
      end

      it 'returns true when the project feature is available' do
        expect(merge_request.target_project).to receive(:feature_available?).with(:merge_request_rebase).at_least(:once).and_return(true)

        is_expected.to be_truthy
      end
    end
  end

  describe '#rebase_in_progress?' do
    it 'returns true when there is a current rebase directory' do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:mtime).and_return(Time.now)

      expect(subject.rebase_in_progress?).to be_truthy
    end

    it 'returns false when there is no rebase directory' do
      allow(File).to receive(:exist?).with(subject.rebase_dir_path).and_return(false)

      expect(subject.rebase_in_progress?).to be_falsey
    end

    it 'returns false when the rebase directory has expired' do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:mtime).and_return(20.minutes.ago)

      expect(subject.rebase_in_progress?).to be_falsey
    end

    it 'returns false when the source project has been removed' do
      allow(subject).to receive(:source_project).and_return(nil)
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:mtime).and_return(Time.now)

      expect(File).not_to have_received(:exist?)
      expect(subject.rebase_in_progress?).to be_falsey
    end
  end

  describe '#squash_in_progress?' do
    it 'returns true when there is a current squash directory' do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:mtime).and_return(Time.now)

      expect(subject.squash_in_progress?).to be_truthy
    end

    it 'returns false when there is no squash directory' do
      allow(File).to receive(:exist?).with(subject.squash_dir_path).and_return(false)

      expect(subject.squash_in_progress?).to be_falsey
    end

    it 'returns false when the squash directory has expired' do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:mtime).and_return(20.minutes.ago)

      expect(subject.squash_in_progress?).to be_falsey
    end

    it 'returns false when the source project has been removed' do
      allow(subject).to receive(:source_project).and_return(nil)
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:mtime).and_return(Time.now)

      expect(File).not_to have_received(:exist?)
      expect(subject.squash_in_progress?).to be_falsey
    end
  end

  describe '#squash?' do
    let(:merge_request) { build(:merge_request, squash: squash) }
    subject { merge_request.squash? }

    context 'unlicensed' do
      before do
        stub_licensed_features(merge_request_squash: false)
      end

      context 'disabled in database' do
        let(:squash) { false }

        it { is_expected.to be_falsy }
      end

      context 'enabled in database' do
        let(:squash) { true }

        it { is_expected.to be_falsy }
      end
    end

    context 'licensed' do
      context 'disabled in database' do
        let(:squash) { false }

        it { is_expected.to be_falsy }
      end

      context 'licensed' do
        let(:squash) { true }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#approvals_before_merge' do
    where(:license_value, :db_value, :expected) do
      true  | 5   | 5
      true  | nil | nil
      false | 5   | nil
      false | nil | nil
    end

    with_them do
      let(:merge_request) { build(:merge_request, approvals_before_merge: db_value) }

      subject { merge_request.approvals_before_merge }

      before do
        stub_licensed_features(merge_request_approvers: license_value)
      end

      it { is_expected.to eq(expected) }
    end
  end
end
