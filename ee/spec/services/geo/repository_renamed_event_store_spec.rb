require 'spec_helper'

describe Geo::RepositoryRenamedEventStore do
  set(:project) { create(:project, path: 'bar') }
  set(:secondary_node) { create(:geo_node) }
  let(:old_path) { 'foo' }
  let(:old_path_with_namespace) { "#{project.namespace.full_path}/foo" }

  subject(:event_store) { described_class.new(project, old_path: old_path, old_path_with_namespace: old_path_with_namespace) }

  describe '#create' do
    it 'does not create an event when not running on a primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect { event_store.create }.not_to change(Geo::RepositoryRenamedEvent, :count)
    end

    context 'when running on a primary node' do
      before do
        allow(Gitlab::Geo).to receive(:primary?) { true }
      end

      it 'does not create an event when there are no secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { subject.create }.not_to change(Geo::RepositoryRenamedEvent, :count)
      end

      it 'creates a renamed event' do
        expect { event_store.create }.to change(Geo::RepositoryRenamedEvent, :count).by(1)
      end

      it 'tracks old and new paths for project repositories' do
        event_store.create

        event = Geo::RepositoryRenamedEvent.last

        expect(event.repository_storage_name).to eq(project.repository_storage)
        expect(event.old_path_with_namespace).to eq(old_path_with_namespace)
        expect(event.new_path_with_namespace).to eq(project.disk_path)
        expect(event.old_wiki_path_with_namespace).to eq("#{old_path_with_namespace}.wiki")
        expect(event.new_wiki_path_with_namespace).to eq(project.wiki.disk_path)
        expect(event.old_path).to eq(old_path)
        expect(event.new_path).to eq(project.path)
      end
    end
  end
end
