require 'spec_helper'

# Disable transactions via :truncate method because a foreign table
# can't see changes inside a transaction of a different connection.
describe Geo::ProjectRegistryFinder, :geo, :truncate do
  include ::EE::GeoHelpers

  let(:secondary) { create(:geo_node) }
  let(:synced_group) { create(:group) }
  let!(:project_not_synced) { create(:project) }
  let(:project_synced) { create(:project) }
  let(:project_repository_dirty) { create(:project) }
  let(:project_wiki_dirty) { create(:project) }

  subject { described_class.new(current_node: secondary) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#count_synced_projects' do
    it 'delegates to #find_synced_projects_registries' do
      expect(subject).to receive(:find_synced_projects_registries).and_call_original

      subject.count_synced_projects
    end

    it 'counts projects that has been synced' do
      create(:geo_project_registry, :sync_failed)
      create(:geo_project_registry, :synced, project: project_synced)
      create(:geo_project_registry, :synced, :repository_dirty, project: project_repository_dirty)
      create(:geo_project_registry, :synced, :wiki_dirty, project: project_wiki_dirty)

      expect(subject.count_synced_projects).to eq 1
    end

    context 'with selective sync' do
      before do
        secondary.update_attribute(:namespaces, [synced_group])
      end

      it 'delegates to #legacy_find_synced_projects' do
        expect(subject).to receive(:legacy_find_synced_projects).and_call_original

        subject.count_synced_projects
      end

      it 'counts projects that has been synced' do
        project_1_in_synced_group = create(:project, group: synced_group)
        project_2_in_synced_group = create(:project, group: synced_group)

        create(:geo_project_registry, :synced, project: project_synced)
        create(:geo_project_registry, :synced, project: project_1_in_synced_group)
        create(:geo_project_registry, :sync_failed, project: project_2_in_synced_group)

        expect(subject.count_synced_projects).to eq 1
      end
    end
  end

  describe '#count_failed_projects' do
    it 'delegates to #find_failed_projects_registries' do
      expect(subject).to receive(:find_failed_projects_registries).and_call_original

      subject.count_failed_projects
    end

    it 'counts projects that sync has failed' do
      create(:geo_project_registry, :synced)
      create(:geo_project_registry, :sync_failed, project: project_synced)
      create(:geo_project_registry, :repository_sync_failed, project: project_repository_dirty)
      create(:geo_project_registry, :wiki_sync_failed, project: project_wiki_dirty)

      expect(subject.count_failed_projects).to eq 3
    end

    context 'with selective sync' do
      before do
        secondary.update_attribute(:namespaces, [synced_group])
      end

      it 'delegates to #legacy_find_failed_projects' do
        expect(subject).to receive(:legacy_find_failed_projects).and_call_original

        subject.count_failed_projects
      end

      it 'counts projects that sync has failed' do
        project_1_in_synced_group = create(:project, group: synced_group)
        project_2_in_synced_group = create(:project, group: synced_group)

        create(:geo_project_registry, :sync_failed, project: project_synced)
        create(:geo_project_registry, :repository_sync_failed, project: project_1_in_synced_group)
        create(:geo_project_registry, :synced, project: project_2_in_synced_group)

        expect(subject.count_failed_projects).to eq 1
      end
    end
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
