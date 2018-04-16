require 'spec_helper'

RSpec.describe Geo::WikiSyncService do
  include ::EE::GeoHelpers

  set(:primary) { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }

  let(:lease) { double(try_obtain: true) }

  subject { described_class.new(project) }

  before do
    stub_current_geo_node(secondary)
  end

  it_behaves_like 'geo base sync execution'

  describe '#execute' do
    let(:project) { create(:project_empty_repo) }
    let(:repository) { project.wiki.repository }
    let(:url_to_repo) { "#{primary.url}#{project.full_path}.wiki.git" }

    before do
      allow(Gitlab::ExclusiveLease).to receive(:new)
        .with(subject.lease_key, anything)
        .and_return(lease)

      allow_any_instance_of(Repository).to receive(:fetch_as_mirror)
        .and_return(true)
    end

    it 'fetches wiki repository with JWT credentials' do
      expect(repository).to receive(:with_config).with("http.#{url_to_repo}.extraHeader" => anything).and_call_original
      expect(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .once

      subject.execute
    end

    it 'releases lease' do
      expect(Gitlab::ExclusiveLease).to receive(:cancel).once.with(
        subject.__send__(:lease_key), anything).and_call_original

      subject.execute
    end

    it 'voids the failure message when it succeeds after an error' do
      registry = create(:geo_project_registry, project: project, last_wiki_sync_failure: 'error')

      expect { subject.execute }.to change { registry.reload.last_wiki_sync_failure}.to(nil)
    end

    it 'does not fetch wiki repository if cannot obtain a lease' do
      allow(lease).to receive(:try_obtain) { false }

      expect(repository).not_to receive(:fetch_as_mirror)

      subject.execute
    end

    it 'rescues exception when Gitlab::Shell::Error is raised' do
      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Shell::Error)

      expect { subject.execute }.not_to raise_error
    end

    it 'rescues exception when Gitlab::Git::RepositoryMirroring::RemoteError is raised' do
      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Git::RepositoryMirroring::RemoteError)

      expect { subject.execute }.not_to raise_error
    end

    it 'rescues exception when Gitlab::Git::Repository::NoRepository is raised' do
      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Git::Repository::NoRepository)

      expect { subject.execute }.not_to raise_error
    end

    it 'increases retry count when Gitlab::Git::Repository::NoRepository is raised' do
      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Git::Repository::NoRepository)

      subject.execute

      expect(Geo::ProjectRegistry.last.wiki_retry_count).to eq(1)
    end

    it 'marks sync as successful if no repository found' do
      registry = create(:geo_project_registry, project: project)

      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Shell::Error.new(Gitlab::GitAccess::ERROR_MESSAGES[:no_repo]))

      subject.execute

      expect(registry.reload.resync_wiki).to be false
      expect(registry.last_wiki_successful_sync_at).not_to be nil
    end

    context 'tracking database' do
      context 'temporary repositories' do
        include_examples 'cleans temporary repositories' do
          let(:repository) { project.wiki.repository }
        end
      end

      it 'creates a new registry if does not exists' do
        expect { subject.execute }.to change(Geo::ProjectRegistry, :count).by(1)
      end

      it 'does not create a new registry if one exists' do
        create(:geo_project_registry, project: project)

        expect { subject.execute }.not_to change(Geo::ProjectRegistry, :count)
      end

      context 'when repository sync succeed' do
        let(:registry) { Geo::ProjectRegistry.find_by(project_id: project.id) }

        it 'sets last_wiki_synced_at' do
          subject.execute

          expect(registry.last_wiki_synced_at).not_to be_nil
        end

        it 'sets last_wiki_successful_sync_at' do
          subject.execute

          expect(registry.last_wiki_successful_sync_at).not_to be_nil
        end

        it 'resets the wiki_verification_checksum_sha' do
          subject.execute

          expect(registry.wiki_verification_checksum_sha).to be_nil
        end

        it 'resets the last_wiki_verification_failure' do
          subject.execute

          expect(registry.last_wiki_verification_failure).to be_nil
        end

        it 'logs success with timings' do
          allow(Gitlab::Geo::Logger).to receive(:info).and_call_original
          expect(Gitlab::Geo::Logger).to receive(:info).with(hash_including(:message, :update_delay_s, :download_time_s)).and_call_original

          subject.execute
        end
      end

      context 'when wiki sync fail' do
        let(:registry) { Geo::ProjectRegistry.find_by(project_id: project.id) }

        before do
          allow(repository).to receive(:fetch_as_mirror)
            .with(url_to_repo, remote_name: 'geo', forced: true)
            .and_raise(Gitlab::Shell::Error.new('shell error'))

          subject.execute
        end

        it 'sets last_wiki_synced_at' do
          expect(registry.last_wiki_synced_at).not_to be_nil
        end

        it 'resets last_wiki_successful_sync_at' do
          expect(registry.last_wiki_successful_sync_at).to be_nil
        end

        it 'sets last_wiki_sync_failure' do
          expect(registry.last_wiki_sync_failure).to eq('Error syncing wiki repository: shell error')
        end
      end

      context 'no Wiki repository' do
        let(:project) { create(:project, :repository) }

        it 'does not raise an error' do
          create(
            :geo_project_registry,
            project: project,
            force_to_redownload_wiki: true
          )

          expect(project.wiki.repository).to receive(:expire_exists_cache).twice.and_call_original
          expect(subject).not_to receive(:fail_registry!)

          subject.execute
        end
      end
    end
  end
end
