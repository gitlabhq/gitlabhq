require 'spec_helper'

describe Gitlab::TreeSummary do
  let(:project) { create(:project, :custom_repo, files: { 'a.txt' => '' }) }
  let(:commit) { project.repository.head_commit }
  let!(:path_lock) { create(:path_lock, project: project, path: 'a.txt') }

  describe '#summarize (entries)' do
    subject { described_class.new(commit, project).summarize.first }

    it 'includes path locks in entries' do
      is_expected.to contain_exactly(
        a_hash_including(file_name: 'a.txt', lock_label: "Locked by #{path_lock.user.name}")
      )
    end
  end
end
