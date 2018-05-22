require 'spec_helper'
require Rails.root.join('ee', 'db', 'geo', 'migrate', '20180510223634_set_resync_flag_for_retried_projects.rb')

describe SetResyncFlagForRetriedProjects, :geo, :migration do
  let(:registry) { table(:project_registry) }

  before do
    registry.create!(project_id: 1, resync_repository: false, resync_wiki: false, repository_retry_count: 0, wiki_retry_count: 0)
    registry.create!(project_id: 2, resync_repository: false, resync_wiki: false, repository_retry_count: 1)
    registry.create!(project_id: 3, resync_repository: false, resync_wiki: false, wiki_retry_count: 1)
  end

  describe '#up' do
    it 'sets resync_repository to true' do
      expect(registry.where(resync_repository: true).count).to eq(0)

      migrate!

      dirty_projects = registry.where(resync_repository: true)
      expect(dirty_projects.count).to eq(1)
      expect(dirty_projects.first.project_id).to eq(2)
    end

    it 'sets resync_wiki to true' do
      expect(registry.where(resync_wiki: true).count). to eq(0)

      migrate!

      dirty_wikis = registry.where(resync_wiki: true)
      expect(dirty_wikis.count).to eq(1)
      expect(dirty_wikis.first.project_id).to eq(3)
    end
  end
end
