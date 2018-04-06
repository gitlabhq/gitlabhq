require 'spec_helper'

describe Geo::RepositorySyncService do
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
    let(:repository) { project.repository }
    let(:url_to_repo) { "#{primary.url}#{project.full_path}.git" }

    before do
      allow(Gitlab::ExclusiveLease).to receive(:new)
        .with(subject.lease_key, anything)
        .and_return(lease)

      allow_any_instance_of(Repository).to receive(:fetch_as_mirror)
        .and_return(true)
    end

    it 'fetches project repository with JWT credentials' do
      expect(repository).to receive(:with_config).with("http.#{url_to_repo}.extraHeader" => anything).and_call_original
      expect(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .once

      subject.execute
    end

    it 'expires repository caches' do
      expect_any_instance_of(Repository).to receive(:expire_all_method_caches).once
      expect_any_instance_of(Repository).to receive(:expire_branch_cache).once
      expect_any_instance_of(Repository).to receive(:expire_content_cache).once

      subject.execute
    end

    it 'returns the lease when succeed' do
      expect(Gitlab::ExclusiveLease).to receive(:cancel).once.with(
        subject.__send__(:lease_key), anything).and_call_original

      subject.execute
    end

    it 'voids the failure message when it succeeds after an error' do
      registry = create(:geo_project_registry, project: project, last_repository_sync_failure: 'error')

      expect { subject.execute }.to change { registry.reload.last_repository_sync_failure}.to(nil)
    end

    it 'returns the lease when sync fail' do
      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Shell::Error)

      expect(Gitlab::ExclusiveLease).to receive(:cancel).once.with(
        subject.__send__(:lease_key), anything).and_call_original

      subject.execute
    end

    it 'does not fetch project repository if cannot obtain a lease' do
      allow(lease).to receive(:try_obtain) { false }

      expect(repository).not_to receive(:fetch_as_mirror)

      subject.execute
    end

    it 'rescues when Gitlab::Shell::Error is raised' do
      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Shell::Error)

      expect { subject.execute }.not_to raise_error
    end

    it 'rescues when Gitlab::Git::RepositoryMirroring::RemoteError is raised' do
      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Git::RepositoryMirroring::RemoteError)

      expect { subject.execute }.not_to raise_error
    end

    it 'rescues exception and fires after_create hook when Gitlab::Git::Repository::NoRepository is raised' do
      allow(repository).to receive(:fetch_as_mirror)
      .with(url_to_repo, remote_name: 'geo', forced: true)
      .and_raise(Gitlab::Git::Repository::NoRepository)

      expect(repository).to receive(:after_create)

      expect { subject.execute }.not_to raise_error
    end

    it 'increases retry count when Gitlab::Git::Repository::NoRepository is raised' do
      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Git::Repository::NoRepository)

      subject.execute

      expect(Geo::ProjectRegistry.last.repository_retry_count).to eq(1)
    end

    it 'marks sync as successful if no repository found' do
      registry = create(:geo_project_registry, project: project)

      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Shell::Error.new(Gitlab::GitAccess::ERROR_MESSAGES[:no_repo]))

      subject.execute

      expect(registry.reload.resync_repository).to be false
      expect(registry.reload.last_repository_successful_sync_at).not_to be nil
    end

    context 'tracking database' do
      context 'temporary repositories' do
        include_examples 'cleans temporary repositories' do
          let(:repository) { project.repository }
        end
      end

      it 'creates a new registry if does not exists' do
        expect { subject.execute }.to change(Geo::ProjectRegistry, :count).by(1)
      end

      it 'does not create a new registry if one exist' do
        create(:geo_project_registry, project: project)

        expect { subject.execute }.not_to change(Geo::ProjectRegistry, :count)
      end

      context 'when repository sync succeed' do
        let(:registry) { Geo::ProjectRegistry.find_by(project_id: project.id) }

        it 'sets last_repository_synced_at' do
          subject.execute

          expect(registry.last_repository_synced_at).not_to be_nil
        end

        it 'sets last_repository_successful_sync_at' do
          subject.execute

          expect(registry.last_repository_successful_sync_at).not_to be_nil
        end

        it 'resets the repository_verification_checksum_sha' do
          subject.execute

          expect(registry.repository_verification_checksum_sha).to be_nil
        end

        it 'resets the last_repository_verification_failure' do
          subject.execute

          expect(registry.last_repository_verification_failure).to be_nil
        end

        it 'logs success with timings' do
          allow(Gitlab::Geo::Logger).to receive(:info).and_call_original
          expect(Gitlab::Geo::Logger).to receive(:info).with(hash_including(:message, :update_delay_s, :download_time_s)).and_call_original

          subject.execute
        end

        it 'sets repository_retry_count and repository_retry_at to nil' do
          registry = create(:geo_project_registry, project: project, repository_retry_count: 2, repository_retry_at: Date.yesterday)

          subject.execute

          expect(registry.reload.repository_retry_count).to be_nil
          expect(registry.repository_retry_at).to be_nil
        end

        context 'with non empty repositories' do
          let(:project) { create(:project, :repository) }

          it 'syncs gitattributes to info/attributes' do
            expect(repository).to receive(:copy_gitattributes)

            subject.execute
          end
        end
      end

      context 'when repository sync fail' do
        let(:registry) { Geo::ProjectRegistry.find_by(project_id: project.id) }

        before do
          allow(repository).to receive(:fetch_as_mirror)
            .with(url_to_repo, remote_name: 'geo', forced: true)
            .and_raise(Gitlab::Shell::Error.new('shell error'))

          subject.execute
        end

        it 'sets last_repository_synced_at' do
          expect(registry.last_repository_synced_at).not_to be_nil
        end

        it 'resets last_repository_successful_sync_at' do
          expect(registry.last_repository_successful_sync_at).to be_nil
        end

        it 'resets repository_retry_count' do
          expect(registry.repository_retry_count).to eq(1)
        end

        it 'resets repository_retry_at' do
          expect(registry.repository_retry_at).to be_present
        end

        it 'sets last_repository_sync_failure' do
          expect(registry.last_repository_sync_failure).to eq('Error syncing repository: shell error')
        end
      end
    end

    context 'retries' do
      it 'tries to fetch repo' do
        create(:geo_project_registry, project: project, repository_retry_count: Geo::BaseSyncService::RETRY_BEFORE_REDOWNLOAD - 1)

        expect(subject).to receive(:sync_repository).with(no_args)

        subject.execute
      end

      it 'sets the redownload flag to false after success' do
        registry = create(:geo_project_registry, project: project, repository_retry_count: Geo::BaseSyncService::RETRY_BEFORE_REDOWNLOAD + 1, force_to_redownload_repository: true)

        subject.execute

        expect(registry.reload.force_to_redownload_repository).to be false
      end

      it 'tries to redownload repo' do
        create(:geo_project_registry, project: project, repository_retry_count: Geo::BaseSyncService::RETRY_BEFORE_REDOWNLOAD + 1)

        expect(subject).to receive(:sync_repository).with(true).and_call_original
        expect(subject.gitlab_shell).to receive(:mv_repository).exactly(2).times.and_call_original

        expect(subject.gitlab_shell).to receive(:add_namespace).with(
          project.repository_storage_path,
          "@failed-geo-sync/#{repository.disk_path}"
        ).and_call_original

        expect(subject.gitlab_shell).to receive(:add_namespace).with(
          project.repository_storage_path,
          repository.disk_path
        ).and_call_original

        expect(subject.gitlab_shell).to receive(:remove_repository).exactly(2).times.and_call_original

        subject.execute

        expect(File.directory?(project.repository.path)).to be true
      end

      it 'tries to redownload repo when force_redownload flag is set' do
        create(
          :geo_project_registry,
          project: project,
          repository_retry_count: Geo::BaseSyncService::RETRY_BEFORE_REDOWNLOAD - 1,
          force_to_redownload_repository: true
        )

        expect(subject).to receive(:sync_repository).with(true)

        subject.execute
      end

      it 'cleans temporary repo after redownload' do
        create(
          :geo_project_registry,
          project: project,
          repository_retry_count: Geo::BaseSyncService::RETRY_BEFORE_REDOWNLOAD - 1,
          force_to_redownload_repository: true
        )

        expect(subject).to receive(:fetch_geo_mirror)
        expect(subject).to receive(:clean_up_temporary_repository).twice

        subject.execute
      end

      it 'successfully redownloads the repository even if the retry time exceeds max value' do
        timestamp = Time.now.utc
        registry = create(
          :geo_project_registry,
          project: project,
          repository_retry_count: Geo::BaseSyncService::RETRY_BEFORE_REDOWNLOAD + 2000,
          repository_retry_at: timestamp,
          force_to_redownload_repository: true
        )

        subject.execute

        # The repository should be redownloaded and cleared without errors. If
        # the timestamp were not capped, we would have seen a "timestamp out
        # of range" in the first update to the project registry.
        registry.reload
        expect(registry.repository_retry_at).to be_nil
      end

      context 'no repository' do
        let(:project) { create(:project) }

        it 'does not raise an error' do
          create(
            :geo_project_registry,
            project: project,
            force_to_redownload_repository: true
          )

          expect(project.repository).to receive(:expire_exists_cache).twice.and_call_original
          expect(subject).not_to receive(:fail_registry!)

          subject.execute
        end
      end
    end
  end
end
