# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::CommitsWithTrailerFinder do
  let(:project) { create(:project, :repository) }

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
end
