require 'spec_helper'

describe MergeRequest do
  using RSpec::Parameterized::TableSyntax

  let(:project) { create(:project, :repository) }

  subject(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  describe 'associations' do
    it { is_expected.to have_many(:approvals).dependent(:delete_all) }
    it { is_expected.to have_many(:approvers).dependent(:delete_all) }
    it { is_expected.to have_many(:approver_groups).dependent(:delete_all) }
    it { is_expected.to have_many(:approved_by_users) }
  end

  describe '#squash_in_progress?' do
    shared_examples 'checking whether a squash is in progress' do
      let(:repo_path) { subject.source_project.repository.path }
      let(:squash_path) { File.join(repo_path, "gitlab-worktree", "squash-#{subject.id}") }

      before do
        system(*%W(#{Gitlab.config.git.bin_path} -C #{repo_path} worktree add --detach #{squash_path} master))
      end

      it 'returns true when there is a current squash directory' do
        expect(subject.squash_in_progress?).to be_truthy
      end

      it 'returns false when there is no squash directory' do
        FileUtils.rm_rf(squash_path)

        expect(subject.squash_in_progress?).to be_falsey
      end

      it 'returns false when the squash directory has expired' do
        time = 20.minutes.ago.to_time
        File.utime(time, time, squash_path)

        expect(subject.squash_in_progress?).to be_falsey
      end

      it 'returns false when the source project has been removed' do
        allow(subject).to receive(:source_project).and_return(nil)

        expect(subject.squash_in_progress?).to be_falsey
      end
    end

    context 'when Gitaly squash_in_progress is enabled' do
      it_behaves_like 'checking whether a squash is in progress'
    end

    context 'when Gitaly squash_in_progress is disabled', :disable_gitaly do
      it_behaves_like 'checking whether a squash is in progress'
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

  %w(sast dast sast_container).each do |type|
    it { is_expected.to delegate_method(:"expose_#{type}_data?").to(:head_pipeline) }
    it { is_expected.to delegate_method(:"has_#{type}_data?").to(:base_pipeline).with_prefix(:base) }
    it { is_expected.to delegate_method(:"#{type}_artifact").to(:head_pipeline).with_prefix(:head) }
    it { is_expected.to delegate_method(:"#{type}_artifact").to(:base_pipeline).with_prefix(:base) }
  end

  describe '#expose_codeclimate_data?' do
    context 'with codeclimate data' do
      let(:pipeline) { double(expose_codeclimate_data?: true) }

      before do
        allow(subject).to receive(:head_pipeline).and_return(pipeline)
        allow(subject).to receive(:base_pipeline).and_return(pipeline)
      end

      it { expect(subject.expose_codeclimate_data?).to be_truthy }
    end

    context 'without codeclimate data' do
      it { expect(subject.expose_codeclimate_data?).to be_falsey }
    end
  end

  describe '#expose_performance_data?' do
    context 'with performance data' do
      let(:pipeline) { double(expose_performance_data?: true) }

      before do
        allow(subject).to receive(:head_pipeline).and_return(pipeline)
        allow(subject).to receive(:base_pipeline).and_return(pipeline)
      end

      it { expect(subject.expose_performance_data?).to be_truthy }
    end

    context 'without performance data' do
      it { expect(subject.expose_performance_data?).to be_falsey }
    end
  end
end
