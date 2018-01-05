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

  describe '#squash_in_progress?' do
    # Create merge request and project before we stub file calls
    before do
      subject
    end

    it 'returns true when there is a current squash directory' do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:mtime).and_return(Time.now)

      expect(subject.squash_in_progress?).to be_truthy
    end

    it 'returns false when there is no squash directory' do
      allow(File).to receive(:exist?).and_return(false)

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

  describe '#base_pipeline' do
    let!(:pipeline) { create(:ci_empty_pipeline, project: subject.project, sha: subject.diff_base_sha) }

    it { expect(subject.base_pipeline).to eq(pipeline) }
  end

  describe '#base_codeclimate_artifact' do
    before do
      allow(subject.base_pipeline).to receive(:codeclimate_artifact)
        .and_return(1)
    end

    it 'delegates to merge request diff' do
      expect(subject.base_codeclimate_artifact).to eq(1)
    end
  end

  describe '#head_codeclimate_artifact' do
    before do
      allow(subject.head_pipeline).to receive(:codeclimate_artifact)
        .and_return(1)
    end

    it 'delegates to merge request diff' do
      expect(subject.head_codeclimate_artifact).to eq(1)
    end
  end

  describe '#base_performance_artifact' do
    before do
      allow(subject.base_pipeline).to receive(:performance_artifact)
        .and_return(1)
    end

    it 'delegates to merge request diff' do
      expect(subject.base_performance_artifact).to eq(1)
    end
  end

  describe '#head_performance_artifact' do
    before do
      allow(subject.head_pipeline).to receive(:performance_artifact)
        .and_return(1)
    end

    it 'delegates to merge request diff' do
      expect(subject.head_performance_artifact).to eq(1)
    end
  end

  describe '#has_codeclimate_data?' do
    context 'with codeclimate artifact' do
      before do
        artifact = double(success?: true)
        allow(subject.head_pipeline).to receive(:codeclimate_artifact).and_return(artifact)
        allow(subject.base_pipeline).to receive(:codeclimate_artifact).and_return(artifact)
      end

      it { expect(subject.has_codeclimate_data?).to be_truthy }
    end

    context 'without codeclimate artifact' do
      it { expect(subject.has_codeclimate_data?).to be_falsey }
    end
  end

  describe '#sast_artifact' do
    it { is_expected.to delegate_method(:sast_artifact).to(:head_pipeline) }
  end

  describe '#has_sast_data?' do
    let(:artifact) { double(success?: true) }

    before do
      allow(merge_request).to receive(:sast_artifact).and_return(artifact)
    end

    it { expect(merge_request.has_sast_data?).to be_truthy }
  end

  describe '#sast_container_artifact' do
    it { is_expected.to delegate_method(:sast_container_artifact).to(:head_pipeline) }
  end

  describe '#has_dast_data?' do
    let(:artifact) { double(success?: true) }

    before do
      allow(merge_request).to receive(:dast_artifact).and_return(artifact)
    end

    it { expect(merge_request.has_dast_data?).to be_truthy }
  end

  describe '#dast_artifact' do
    it { is_expected.to delegate_method(:dast_artifact).to(:head_pipeline) }
  end
end
