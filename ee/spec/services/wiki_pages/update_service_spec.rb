require 'spec_helper'

describe WikiPages::UpdateService do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:page)    { create(:wiki_page) }

  let(:opts) do
    {
      content: 'New content for wiki page',
      format: 'markdown',
      message: 'New wiki message'
    }
  end

  subject(:service) { described_class.new(project, user, opts) }

  before do
    project.add_master(user)
  end

  describe '#execute' do
    it 'calls Geo::RepositoryUpdatedService when running on a Geo primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { true }

      repository_updated_service = instance_double('::Geo::RepositoryUpdatedService')
      expect(::Geo::RepositoryUpdatedService).to receive(:new).with(project, source: Geo::RepositoryUpdatedEvent::WIKI) { repository_updated_service }
      expect(repository_updated_service).to receive(:execute)

      service.execute(page)
    end

    it 'does not call Geo::RepositoryUpdatedService when not running on a Geo primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect(::Geo::RepositoryUpdatedService).not_to receive(:new).with(project, source: Geo::RepositoryUpdatedEvent::WIKI)

      service.execute(page)
    end
  end
end
