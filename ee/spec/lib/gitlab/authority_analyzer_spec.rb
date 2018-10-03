require 'spec_helper'

describe Gitlab::AuthorityAnalyzer do
  describe '#calculate' do
    let(:project) { create(:project, :repository) }
    let(:author) { create(:user) }
    let(:user_a) { create(:user) }
    let(:user_b) { create(:user) }
    let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }
    let(:files) { [double(:file, deleted_file: true, old_path: 'foo')] }

    let(:commits) do
      [
        double(:commit, author: author),
        double(:commit, author: user_a),
        double(:commit, author: user_a),
        double(:commit, author: user_b),
        double(:commit, author: author)
      ]
    end

    let(:approvers) { described_class.new(merge_request, author).calculate }

    before do
      merge_request.compare = double(:compare, raw_diffs: files)
      allow(merge_request.target_project.repository).to receive(:commits).and_return(commits)
    end

    it 'returns contributors in order, without skip_user' do
      expect(approvers).to contain_exactly(user_a, user_b)
    end
  end
end
