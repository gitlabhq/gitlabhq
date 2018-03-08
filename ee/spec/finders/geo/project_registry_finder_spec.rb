require 'spec_helper'

describe Geo::ProjectRegistryFinder, :geo do
  include ::EE::GeoHelpers

  let(:secondary) { create(:geo_node) }
  let(:synced_group) { create(:group) }
  let!(:project_not_synced) { create(:project) }
  let(:project_synced) { create(:project) }
  let(:project_repository_dirty) { create(:project) }
  let(:project_wiki_dirty) { create(:project) }
  let(:project_repository_verified) { create(:project) }
  let(:project_repository_verification_failed) { create(:project) }
  let(:project_wiki_verified) { create(:project) }
  let(:project_wiki_verification_failed) { create(:project) }

  subject { described_class.new(current_node: secondary) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#count_synced_repositories' do
    it 'delegates to #find_synced_repositories' do
      expect(subject).to receive(:find_synced_repositories).and_call_original

      subject.count_synced_repositories
    end

    it 'counts repositories that have been synced' do
      create(:geo_project_registry, :sync_failed)
      create(:geo_project_registry, :synced, project: project_synced)
      create(:geo_project_registry, :synced, :repository_dirty, project: project_repository_dirty)
      create(:geo_project_registry, :synced, :wiki_dirty, project: project_wiki_dirty)

      expect(subject.count_synced_repositories).to eq 2
    end

    context 'with selective sync' do
      before do
        secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
      end

      it 'delegates to #legacy_find_synced_repositories' do
        expect(subject).to receive(:legacy_find_synced_repositories).and_call_original

        subject.count_synced_repositories
      end

      it 'counts projects that has been synced' do
        project_1_in_synced_group = create(:project, group: synced_group)
        project_2_in_synced_group = create(:project, group: synced_group)

        create(:geo_project_registry, :synced, project: project_synced)
        create(:geo_project_registry, :synced, project: project_1_in_synced_group)
        create(:geo_project_registry, :sync_failed, project: project_2_in_synced_group)

        expect(subject.count_synced_repositories).to eq 1
      end
    end
  end

  describe '#count_synced_wikis' do
    before do
      allow(subject).to receive(:use_legacy_queries?).and_return(true)
    end

    it 'delegates to #legacy_find_synced_wikis' do
      expect(subject).to receive(:legacy_find_synced_wikis).and_call_original

      subject.count_synced_wikis
    end

    it 'counts wiki that have been synced' do
      create(:geo_project_registry, :sync_failed)
      create(:geo_project_registry, :synced, project: project_synced)
      create(:geo_project_registry, :synced, :repository_dirty, project: project_repository_dirty)
      create(:geo_project_registry, :synced, :wiki_dirty, project: project_wiki_dirty)

      expect(subject.count_synced_wikis).to eq 2
    end

    it 'does not count disabled wikis' do
      create(:geo_project_registry, :synced, project: project_synced)
      create(:geo_project_registry, :synced, project: create(:project, :wiki_disabled))

      expect(subject.count_synced_wikis).to eq 1
    end

    context 'with selective sync' do
      before do
        secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
      end

      it 'delegates to #legacy_find_synced_wiki' do
        expect(subject).to receive(:legacy_find_synced_wikis).and_call_original

        subject.count_synced_wikis
      end

      it 'counts projects that has been synced' do
        project_1_in_synced_group = create(:project, group: synced_group)
        project_2_in_synced_group = create(:project, group: synced_group)

        create(:geo_project_registry, :synced, project: project_synced)
        create(:geo_project_registry, :synced, project: project_1_in_synced_group)
        create(:geo_project_registry, :sync_failed, project: project_2_in_synced_group)

        expect(subject.count_synced_wikis).to eq 1
      end
    end
  end

  describe '#count_failed_repositories' do
    it 'delegates to #find_failed_project_registries' do
      expect(subject).to receive(:find_failed_project_registries).with('repository').and_call_original

      subject.count_failed_repositories
    end

    it 'counts projects that sync has failed' do
      create(:geo_project_registry, :synced)
      create(:geo_project_registry, :sync_failed, project: project_synced)
      create(:geo_project_registry, :repository_sync_failed, project: project_repository_dirty)
      create(:geo_project_registry, :wiki_sync_failed, project: project_wiki_dirty)

      expect(subject.count_failed_repositories).to eq 2
    end

    context 'with selective sync' do
      before do
        secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
      end

      it 'delegates to #find_failed_repositories' do
        expect(subject).to receive(:find_failed_project_registries).with('repository').and_call_original

        subject.count_failed_repositories
      end

      it 'counts projects that sync has failed' do
        project_1_in_synced_group = create(:project, group: synced_group)
        project_2_in_synced_group = create(:project, group: synced_group)

        create(:geo_project_registry, :sync_failed, project: project_synced)
        create(:geo_project_registry, :repository_sync_failed, project: project_1_in_synced_group)
        create(:geo_project_registry, :synced, project: project_2_in_synced_group)

        expect(subject.count_failed_repositories).to eq 1
      end
    end
  end

  describe '#count_failed_wikis' do
    it 'delegates to #find_failed_project_registries' do
      expect(subject).to receive(:find_failed_project_registries).with('wiki').and_call_original

      subject.count_failed_wikis
    end

    it 'counts projects that sync has failed' do
      create(:geo_project_registry, :synced)
      create(:geo_project_registry, :sync_failed, project: project_synced)
      create(:geo_project_registry, :repository_sync_failed, project: project_repository_dirty)
      create(:geo_project_registry, :wiki_sync_failed, project: project_wiki_dirty)

      expect(subject.count_failed_wikis).to eq 2
    end

    context 'with selective sync' do
      before do
        secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
      end

      it 'delegates to #find_failed_wikis' do
        expect(subject).to receive(:find_failed_project_registries).with('wiki').and_call_original

        subject.count_failed_wikis
      end

      it 'counts projects that sync has failed' do
        project_1_in_synced_group = create(:project, group: synced_group)
        project_2_in_synced_group = create(:project, group: synced_group)

        create(:geo_project_registry, :sync_failed, project: project_synced)
        create(:geo_project_registry, :wiki_sync_failed, project: project_1_in_synced_group)
        create(:geo_project_registry, :synced, project: project_2_in_synced_group)

        expect(subject.count_failed_wikis).to eq 1
      end
    end
  end

  describe '#count_verification_failed_repositories' do
    it 'delegates to #find_verification_failed_project_registries' do
      expect(subject).to receive(:find_verification_failed_project_registries).with('repository').and_call_original

      subject.count_verification_failed_repositories
    end

    it 'counts projects that verification has failed' do
      create(:geo_project_registry, :repository_verified, project: project_repository_verified)
      create(:geo_project_registry, :repository_verification_failed, project: project_repository_verification_failed)
      create(:geo_project_registry, :wiki_verified, project: project_wiki_verified)
      create(:geo_project_registry, :wiki_verification_failed, project: project_wiki_verification_failed)

      expect(subject.count_verification_failed_repositories).to eq 1
    end

    context 'with legacy queries' do
      before do
        allow(subject).to receive(:use_legacy_queries?).and_return(true)
      end

      it 'delegates to #legacy_find_filtered_verification_failed_projects' do
        expect(subject).to receive(:legacy_find_filtered_verification_failed_projects).and_call_original

        subject.find_verification_failed_project_registries('repository')
      end

      it 'counts projects that verification has failed' do
        create(:geo_project_registry, :repository_verified, project: project_repository_verified)
        create(:geo_project_registry, :repository_verification_failed, project: project_repository_verification_failed)
        create(:geo_project_registry, :wiki_verified, project: project_wiki_verified)
        create(:geo_project_registry, :wiki_verification_failed, project: project_wiki_verification_failed)

        expect(subject.count_verification_failed_repositories).to eq 1
      end
    end
  end

  describe '#count_verification_failed_wikis' do
    it 'delegates to #find_verification_failed_project_registries' do
      expect(subject).to receive(:find_verification_failed_project_registries).with('wiki').and_call_original

      subject.count_verification_failed_wikis
    end

    it 'counts projects that verification has failed' do
      create(:geo_project_registry, :repository_verified, project: project_repository_verified)
      create(:geo_project_registry, :repository_verification_failed, project: project_repository_verification_failed)
      create(:geo_project_registry, :wiki_verified, project: project_wiki_verified)
      create(:geo_project_registry, :wiki_verification_failed, project: project_wiki_verification_failed)

      expect(subject.count_verification_failed_wikis).to eq 1
    end

    context 'with legacy queries' do
      before do
        allow(subject).to receive(:use_legacy_queries?).and_return(true)
      end

      it 'delegates to #legacy_find_filtered_verification_failed_projects' do
        expect(subject).to receive(:legacy_find_filtered_verification_failed_projects).and_call_original

        subject.find_verification_failed_project_registries('wiki')
      end

      it 'counts projects that verification has failed' do
        create(:geo_project_registry, :repository_verified, project: project_repository_verified)
        create(:geo_project_registry, :repository_verification_failed, project: project_repository_verification_failed)
        create(:geo_project_registry, :wiki_verified, project: project_wiki_verified)
        create(:geo_project_registry, :wiki_verification_failed, project: project_wiki_verification_failed)

        expect(subject.count_verification_failed_wikis).to eq 1
      end
    end
  end

  describe '#find_failed_project_registries' do
    let(:project_1_in_synced_group) { create(:project, group: synced_group) }
    let(:project_2_in_synced_group) { create(:project, group: synced_group) }

    let!(:synced) { create(:geo_project_registry, :synced) }
    let!(:sync_failed) { create(:geo_project_registry, :sync_failed, project: project_synced) }
    let!(:repository_sync_failed) { create(:geo_project_registry, :repository_sync_failed, project: project_1_in_synced_group) }
    let!(:wiki_sync_failed) { create(:geo_project_registry, :wiki_sync_failed, project: project_2_in_synced_group) }

    it 'delegates to #find_failed_project_registries' do
      expect(subject).to receive(:find_failed_project_registries).with('repository').and_call_original

      subject.count_failed_repositories
    end

    it 'returns only project registries that repository sync has failed' do
      expect(subject.find_failed_project_registries('repository')).to match_array([sync_failed, repository_sync_failed])
    end

    it 'returns only project registries that wiki sync has failed' do
      expect(subject.find_failed_project_registries('wiki')).to match_array([sync_failed, wiki_sync_failed])
    end

    context 'with selective sync' do
      before do
        secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
      end

      it 'delegates to #legacy_find_filtered_failed_projects' do
        expect(subject).to receive(:legacy_find_filtered_failed_projects).and_call_original

        subject.find_failed_project_registries
      end

      it 'returns project registries that sync has failed' do
        expect(subject.find_failed_project_registries).to match_array([repository_sync_failed, wiki_sync_failed])
      end

      it 'returns only project registries that repository sync has failed' do
        create(:geo_project_registry, :repository_sync_failed)

        expect(subject.find_failed_project_registries('repository')).to match_array([repository_sync_failed])
      end

      it 'returns only project registries that wiki sync has failed' do
        create(:geo_project_registry, :wiki_sync_failed)

        expect(subject.find_failed_project_registries('wiki')).to match_array([wiki_sync_failed])
      end
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  context 'FDW', :delete do
    before do
      skip('FDW is not configured') if Gitlab::Database.postgresql? && !Gitlab::Geo::Fdw.enabled?
    end

    describe '#fdw_find_enabled_wikis' do
      it 'does not count disabled wikis' do
        expect(subject).to receive(:fdw_find_enabled_wikis).and_call_original

        create(:geo_project_registry, :synced, project: project_synced)
        create(:geo_project_registry, :synced, project: create(:project, :wiki_disabled))

        expect(subject.count_synced_wikis).to eq 1
      end
    end

    describe '#find_unsynced_projects' do
      it 'delegates to #fdw_find_unsynced_projects' do
        expect(subject).to receive(:fdw_find_unsynced_projects).and_call_original

        subject.find_unsynced_projects(batch_size: 10)
      end

      it 'delegates to #legacy_find_unsynced_projects when node has selective sync' do
        secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

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
        secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])

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

  shared_examples 'find registries for repositories/wikis' do |use_fdw|
    before do
      allow(Gitlab::Geo::Fdw).to receive(:enabled?).and_return(use_fdw)
    end

    let(:verified_repository_state) { create(:repository_state, :repository_verified, :wiki_verified, last_repository_verification_at: 10.minutes.from_now) }
    let(:verified_project) { create(:project, repository_state: verified_repository_state) }
    let(:verified_registry) do
      create(:geo_project_registry,
             project: verified_project,
             last_repository_verification_at: Time.now,
             last_repository_successful_sync_at: 5.minutes.from_now)
    end

    context 'with the primary verification failure' do
      it 'finds when not failed' do
        verified_repository_state.last_repository_verification_failed = false
        verified_repository_state.last_wiki_verification_failed = false
        verified_registry

        expect(subject.find_registries_to_verify.count).to eq 1
      end

      it 'does not find when failed' do
        verified_repository_state.last_repository_verification_failed = true
        verified_repository_state.last_wiki_verification_failed = true
        verified_registry

        expect(subject.find_registries_to_verify.count).to eq 0
      end

      it 'finds when either repo/wiki fails' do
        verified_repository_state.last_repository_verification_failed = true
        verified_repository_state.last_wiki_verification_failed = false
        verified_registry

        expect(subject.find_registries_to_verify.count).to eq 1
      end
    end

    context 'with the primary verification checksum' do
      it 'finds with a checksum' do
        verified_repository_state.repository_verification_checksum = 'my-checksum'
        verified_repository_state.wiki_verification_checksum = 'my-checksum'
        verified_registry

        expect(subject.find_registries_to_verify.count).to eq 1
      end

      it 'does not find a checksum' do
        verified_repository_state.repository_verification_checksum = nil
        verified_repository_state.wiki_verification_checksum = nil
        verified_registry

        expect(subject.find_registries_to_verify.count).to eq 0
      end

      it 'finds when either repo/wiki has a checksum' do
        verified_repository_state.repository_verification_checksum = 'my-checksum'
        verified_repository_state.wiki_verification_checksum = nil
        verified_registry

        expect(subject.find_registries_to_verify.count).to eq 1
      end
    end

    context 'with the primary repository verification date ' do
      let(:verified_project) do
        project = create(:project, repository_state: verified_repository_state)
        project.update_attribute(:last_repository_updated_at, 30.minutes.ago)
        project
      end
      let(:verified_registry) do
        create(:geo_project_registry,
               project: verified_project,
               last_repository_verification_at: 25.minutes.ago,
               last_wiki_verification_at: 25.minutes.ago,
               last_repository_successful_sync_at: 5.minutes.from_now,
               last_wiki_successful_sync_at: 5.minutes.from_now)
      end

      it 'finds if primary verified after the primary repository was updated' do
        verified_repository_state.last_repository_verification_at = 20.minutes.ago
        verified_registry

        expect(subject.find_registries_to_verify.count).to eq 1
      end

      it 'does not find if primary repository updated after primary verification' do
        verified_repository_state.last_repository_verification_at = 35.minutes.ago
        verified_repository_state.last_wiki_verification_at = 35.minutes.ago
        verified_registry

        expect(subject.find_registries_to_verify.count).to eq 0
      end

      it 'finds if primary wiki verified after the primary repository was updated' do
        verified_repository_state.last_repository_verification_at = 35.minutes.ago
        verified_repository_state.last_wiki_verification_at = 20.minutes.ago
        verified_registry

        expect(subject.find_registries_to_verify.count).to eq 1
      end

      it 'does not find if primary verification did not happen' do
        verified_repository_state.last_repository_verification_at = nil
        verified_repository_state.last_wiki_verification_at = nil
        verified_registry

        expect(subject.find_registries_to_verify.count).to eq 0
      end

      it 'finds if primary was verified after the secondary was verified' do
        verified_registry.update_attribute(:last_repository_verification_at, verified_repository_state.last_repository_verification_at - 5.minutes)

        expect(subject.find_registries_to_verify.count).to eq 1
      end

      it 'does not find if primary was verified before the secondary was verified' do
        verified_registry.update_attributes(
          last_repository_verification_at: verified_repository_state.last_repository_verification_at + 5.minutes,
          last_wiki_verification_at: verified_repository_state.last_wiki_verification_at + 5.minutes
        )

        expect(subject.find_registries_to_verify.count).to eq 0
      end
    end

    it 'returns repositories failed more than 24 hours ago' do
      create(:geo_project_registry,
             project: verified_project,
             repository_verification_checksum: nil,
             last_repository_verification_failed: true,
             last_repository_verification_at: 2.days.ago)

      expect(subject.find_registries_to_verify.count).to eq 1
    end

    it 'does not return repositories failed less than 24 hours ago' do
      create(:geo_project_registry, :repository_verification_failed, last_repository_verification_at: 5.hours.ago)

      expect(subject.find_registries_to_verify.count).to eq 0
    end
  end

  describe '#find_registries_to_verify', :delete do
    context 'using FDW' do
      include_examples 'find registries for repositories/wikis', true
    end

    context 'using Legacy' do
      include_examples 'find registries for repositories/wikis', false
    end
  end

  context 'Legacy' do
    before do
      allow(Gitlab::Geo::Fdw).to receive(:enabled?).and_return(false)
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
