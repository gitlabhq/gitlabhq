require 'spec_helper'

describe Geo::FileDownloadService do
  include ::EE::GeoHelpers

  set(:primary)  { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)

    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(true)
  end

  shared_examples_for 'a service that downloads the file and registers the sync result' do |file_type|
    let(:download_service) { described_class.new(file_type, file.id) }
    let(:registry) { file_type == 'job_artifact' ? Geo::JobArtifactRegistry : Geo::FileRegistry }
    subject(:execute!) { download_service.execute }

    context 'for a new file' do
      context 'when the downloader fails before attempting a transfer' do
        it 'logs that the download failed before attempting a transfer' do
          result = double(:result, success: false, bytes_downloaded: 0, primary_missing_file: false, failed_before_transfer: true)
          downloader = double(:downloader, execute: result)
          expect(download_service).to receive(:downloader).and_return(downloader)
          expect(Gitlab::Geo::Logger).to receive(:info).with(hash_including(:message, :download_time_s, download_success: false, bytes_downloaded: 0, failed_before_transfer: true)).and_call_original

          execute!
        end
      end

      context 'when the downloader attempts a transfer' do
        context 'when the file is successfully downloaded' do
          before do
            stub_transfer_result(bytes_downloaded: 100, success: true)
          end

          it 'registers the file' do
            expect { execute! }.to change { registry.count }.by(1)
          end

          it 'marks the file as synced' do
            expect { execute! }.to change { registry.synced.count }.by(1)
          end

          it 'does not mark the file as missing on the primary' do
            execute!

            expect(registry.last.missing_on_primary).to be_falsey
          end

          it 'logs the result' do
            expect(Gitlab::Geo::Logger).to receive(:info).with(hash_including(:message, :download_time_s, download_success: true, bytes_downloaded: 100)).and_call_original

            execute!
          end
        end

        context 'when the file fails to download' do
          context 'when the file is missing on the primary' do
            before do
              stub_transfer_result(bytes_downloaded: 100, success: true, primary_missing_file: true)
            end

            it 'registers the file' do
              expect { execute! }.to change { registry.count }.by(1)
            end

            it 'marks the file as synced' do
              expect { execute! }.to change { registry.synced.count }.by(1)
            end

            it 'marks the file as missing on the primary' do
              execute!

              expect(registry.last.missing_on_primary).to be_truthy
            end

            it 'logs the result' do
              expect(Gitlab::Geo::Logger).to receive(:info).with(hash_including(:message, :download_time_s, download_success: true, bytes_downloaded: 100, primary_missing_file: true)).and_call_original

              execute!
            end
          end

          context 'when the file is not missing on the primary' do
            before do
              stub_transfer_result(bytes_downloaded: 0, success: false)
            end

            it 'registers the file' do
              expect { execute! }.to change { registry.count }.by(1)
            end

            it 'marks the file as failed to sync' do
              expect { execute! }.to change { registry.failed.count }.by(1)
            end

            it 'does not mark the file as missing on the primary' do
              execute!

              expect(registry.last.missing_on_primary).to be_falsey
            end

            it 'sets a retry date and increments the retry count' do
              execute!

              expect(registry.last.retry_count).to eq(1)
              expect(registry.last.retry_at).to be_present
            end
          end
        end
      end
    end

    context 'for a registered file that failed to sync' do
      let!(:registry_entry) do
        if file_type == 'job_artifact'
          create(:geo_job_artifact_registry, success: false, artifact_id: file.id)
        else
          create(:geo_file_registry, file_type.to_sym, success: false, file_id: file.id)
        end
      end

      context 'when the file is successfully downloaded' do
        before do
          stub_transfer_result(bytes_downloaded: 100, success: true)
        end

        it 'does not register a new file' do
          expect { execute! }.not_to change { registry.count }
        end

        it 'marks the file as synced' do
          expect { execute! }.to change { registry.synced.count }.by(1)
        end

        context 'when the file was marked as missing on the primary' do
          before do
            registry_entry.update_column(:missing_on_primary, true)
          end

          it 'marks the file as no longer missing on the primary' do
            execute!

            expect(registry_entry.reload.missing_on_primary).to be_falsey
          end
        end

        context 'when the file was not marked as missing on the primary' do
          it 'does not mark the file as missing on the primary' do
            execute!

            expect(registry_entry.reload.missing_on_primary).to be_falsey
          end
        end
      end

      context 'when the file fails to download' do
        context 'when the file is missing on the primary' do
          before do
            stub_transfer_result(bytes_downloaded: 100, success: true, primary_missing_file: true)
          end

          it 'does not register a new file' do
            expect { execute! }.not_to change { registry.count }
          end

          it 'marks the file as synced' do
            expect { execute! }.to change { registry.synced.count }.by(1)
          end

          it 'marks the file as missing on the primary' do
            execute!

            expect(registry_entry.reload.missing_on_primary).to be_truthy
          end

          it 'logs the result' do
            expect(Gitlab::Geo::Logger).to receive(:info).with(hash_including(:message, :download_time_s, download_success: true, bytes_downloaded: 100, primary_missing_file: true)).and_call_original

            execute!
          end
        end

        context 'when the file is not missing on the primary' do
          before do
            stub_transfer_result(bytes_downloaded: 0, success: false)
          end

          it 'does not register a new file' do
            expect { execute! }.not_to change { registry.count }
          end

          it 'does not change the success flag' do
            expect { execute! }.not_to change { registry.failed.count }
          end

          it 'does not mark the file as missing on the primary' do
            execute!

            expect(registry_entry.reload.missing_on_primary).to be_falsey
          end

          it 'changes the retry date and increments the retry count' do
            expect { execute! }.to change { registry_entry.reload.retry_count }.from(nil).to(1)
          end

          it 'changes the retry date and increments the retry count' do
            expect { execute! }.to change { registry_entry.reload.retry_at }
          end
        end
      end
    end
  end

  describe '#execute' do
    context 'user avatar' do
      it_behaves_like "a service that downloads the file and registers the sync result", 'avatar' do
        let(:file) { create(:upload, model: build(:user)) }
      end
    end

    context 'group avatar' do
      it_behaves_like "a service that downloads the file and registers the sync result", 'avatar' do
        let(:file) { create(:upload, model: build(:group)) }
      end
    end

    context 'project avatar' do
      it_behaves_like "a service that downloads the file and registers the sync result", 'avatar' do
        let(:file) { create(:upload, model: build(:project)) }
      end
    end

    context 'with an attachment' do
      it_behaves_like "a service that downloads the file and registers the sync result", 'attachment' do
        let(:file) { create(:upload, :attachment_upload) }
      end
    end

    context 'with a snippet' do
      it_behaves_like "a service that downloads the file and registers the sync result", 'personal_file' do
        let(:file) { create(:upload, :personal_snippet_upload) }
      end
    end

    context 'with file upload' do
      it_behaves_like "a service that downloads the file and registers the sync result", 'file' do
        let(:file) { create(:upload, :issuable_upload) }
      end
    end

    context 'with namespace file upload' do
      it_behaves_like "a service that downloads the file and registers the sync result", 'namespace_file' do
        let(:file) { create(:upload, :namespace_upload) }
      end
    end

    context 'LFS object' do
      it_behaves_like "a service that downloads the file and registers the sync result", 'lfs' do
        let(:file) { create(:lfs_object) }
      end
    end

    context 'job artifacts' do
      it_behaves_like "a service that downloads the file and registers the sync result", 'job_artifact' do
        let(:file) { create(:ci_job_artifact) }
      end
    end

    context 'bad object type' do
      it 'raises an error' do
        expect { described_class.new(:bad, 1).execute }.to raise_error(NameError)
      end
    end

    def stub_transfer_result(bytes_downloaded:, success: false, primary_missing_file: false)
      result = double(:transfer_result,
                      bytes_downloaded: bytes_downloaded,
                      success: success,
                      primary_missing_file: primary_missing_file)
      instance = double("(instance of Gitlab::Geo::Transfer)", download_from_primary: result)
      allow(Gitlab::Geo::Transfer).to receive(:new).and_return(instance)
    end
  end
end
