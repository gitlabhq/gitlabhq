# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::ChangelogCommitsFinder, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }

  describe '#each_page' do
    it 'only yields commits with the given trailer' do
      finder = described_class.new(
        project: project,
        from: '570e7b2abdd848b95f2f578043fc23bd6f6fd24d',
        to: 'c7fbe50c7c7419d9701eebe64b1fdacc3df5b9dd'
      )

      commits = finder.each_page('Signed-off-by').to_a.flatten

      expect(commits.length).to eq(1)
      expect(commits.first.id).to eq('5937ac0a7beb003549fc5fd26fc247adbce4a52e')
      expect(commits.first.trailers).to eq(
        'Signed-off-by' => 'Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>'
      )
    end

    it 'ignores commits that are reverted' do
      # This range of commits is found on the branch
      # https://gitlab.com/gitlab-org/gitlab-test/-/commits/trailers.
      finder = described_class.new(
        project: project,
        from: 'ddd0f15ae83993f5cb66a927a28673882e99100b',
        to: '694e6c2f08cad00d183682d9dede99615998a630'
      )

      commits = finder.each_page('Changelog').to_a.flatten

      expect(commits).to be_empty
    end

    it 'includes revert commits if they have a trailer' do
      finder = described_class.new(
        project: project,
        from: 'ddd0f15ae83993f5cb66a927a28673882e99100b',
        to: 'f0a5ed60d24c98ec6d00ac010c1f3f01ee0a8373'
      )

      initial_commit = project.commit('ed2e92bf50b3da2c7cbbab053f4977a4ecbd109a')
      revert_commit = project.commit('f0a5ed60d24c98ec6d00ac010c1f3f01ee0a8373')

      commits = finder.each_page('Changelog').to_a.flatten

      expect(commits).to eq([revert_commit, initial_commit])
    end

    it 'supports paginating of commits' do
      finder = described_class.new(
        project: project,
        from: 'c1acaa58bbcbc3eafe538cb8274ba387047b69f8',
        to: '5937ac0a7beb003549fc5fd26fc247adbce4a52e',
        per_page: 1
      )

      commits = finder.each_page('Signed-off-by')

      expect(commits.count).to eq(4)
    end
  end

  describe '#revert_commit_sha' do
    let(:finder) { described_class.new(project: project, from: 'a', to: 'b') }

    it 'returns the SHA of a reverted commit' do
      commit = double(
        :commit,
        description: 'This reverts commit 152c03af1b09f50fa4b567501032b106a3a81ff3.'
      )

      expect(finder.send(:revert_commit_sha, commit))
        .to eq('152c03af1b09f50fa4b567501032b106a3a81ff3')
    end

    it 'returns nil when the commit is not a revert commit' do
      commit = double(:commit, description: 'foo')

      expect(finder.send(:revert_commit_sha, commit)).to be_nil
    end

    it 'returns nil when the commit has no description' do
      commit = double(:commit, description: nil)

      expect(finder.send(:revert_commit_sha, commit)).to be_nil
    end
  end
end
