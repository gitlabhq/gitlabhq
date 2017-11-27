require 'spec_helper'

# Disable transactions via :truncate method because a foreign table
# can't see changes inside a transaction of a different connection.
describe Geo::ProjectRegistryFinder, :geo, :truncate do
  include ::EE::GeoHelpers

  let(:secondary) { create(:geo_node) }
  let(:synced_group) { create(:group) }
  let!(:project_not_synced) { create(:project) }
  let(:project_repository_dirty) { create(:project) }
  let(:project_wiki_dirty) { create(:project) }

  subject { described_class.new(current_node: secondary) }

  before do
    stub_current_geo_node(secondary)
  end

  context 'FDW' do
    before do
      skip('FDW is not configured') if Gitlab::Database.postgresql? && !Gitlab::Geo.fdw?
    end

    describe '#find_unsynced_projects' do
      it 'delegates to #fdw_find_unsynced_projects' do
        expect(subject).to receive(:fdw_find_unsynced_projects).and_call_original

        subject.find_unsynced_projects(batch_size: 10)
      end

      it 'delegates to #legacy_find_unsynced_projects when node has selective sync' do
        secondary.update_attribute(:namespaces, [synced_group])

        expect(subject).to receive(:legacy_find_unsynced_projects).and_call_original

        subject.find_unsynced_projects(batch_size: 10)
      end

      it 'returns projects without an entry on the tracking database' do
        create(:geo_project_registry, :synced, :repository_dirty, project: project_repository_dirty)

        projects = subject.find_unsynced_projects(batch_size: 10)

        expect(projects.count).to eq(1)
        expect(projects.first.id).to eq(project_not_synced.id)
      end
    end

    describe '#find_projects_updated_recently' do
      it 'delegates to #fdw_find_projects_updated_recently' do
        expect(subject).to receive(:fdw_find_projects_updated_recently).and_call_original

        subject.find_projects_updated_recently(batch_size: 10)
      end

      it 'delegates to #legacy_find_projects_updated_recently when node has selective sync' do
        secondary.update_attribute(:namespaces, [synced_group])

        expect(subject).to receive(:legacy_find_projects_updated_recently).and_call_original

        subject.find_projects_updated_recently(batch_size: 10)
      end

      it 'returns projects with a dirty entry on the tracking database' do
        project_not_synced = create(:project)
        project_repository_dirty = create(:project)
        project_wiki_dirty = create(:project)

        create(:geo_project_registry, :synced, :repository_dirty, project: project_repository_dirty)
        create(:geo_project_registry, :synced, :wiki_dirty, project: project_wiki_dirty)

        projects = subject.find_projects_updated_recently(batch_size: 10)

        expect(projects.pluck(:id)).to match_array([project_repository_dirty.id, project_wiki_dirty.id])
      end
    end
  end

  context 'Legacy' do
    before do
      allow(Gitlab::Geo).to receive(:fdw?).and_return(false)
    end

    describe '#find_unsynced_projects' do
      it 'delegates to #legacy_find_unsynced_projects' do
        expect(subject).to receive(:legacy_find_unsynced_projects).and_call_original

        subject.find_unsynced_projects(batch_size: 10)
      end

      it 'returns projects without an entry on the tracking database' do
        create(:geo_project_registry, :synced, :repository_dirty, project: project_repository_dirty)

        projects = subject.find_unsynced_projects(batch_size: 10)

        expect(projects).to match_array([project_not_synced])
      end
    end

    describe '#find_projects_updated_recently' do
      it 'delegates to #legacy_find_projects_updated_recently' do
        expect(subject).to receive(:legacy_find_projects_updated_recently).and_call_original

        subject.find_projects_updated_recently(batch_size: 10)
      end

      it 'returns projects with a dirty entry on the tracking database' do
        create(:geo_project_registry, :synced, :repository_dirty, project: project_repository_dirty)
        create(:geo_project_registry, :synced, :wiki_dirty, project: project_wiki_dirty)

        projects = subject.find_projects_updated_recently(batch_size: 10)

        expect(projects.pluck(:id)).to match_array([project_repository_dirty.id, project_wiki_dirty.id])
      end
    end
  end
end
