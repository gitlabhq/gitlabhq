require 'spec_helper'

describe Gitlab::Geo::LogCursor::Events::JobArtifactDeletedEvent, :postgresql, :clean_gitlab_redis_shared_state do
  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  let(:event_log) { create(:geo_event_log, :job_artifact_deleted_event) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
  let(:job_artifact_deleted_event) { event_log.job_artifact_deleted_event }
  let(:job_artifact) { job_artifact_deleted_event.job_artifact }

  subject { described_class.new(job_artifact_deleted_event, Time.now, logger) }

  around do |example|
    Sidekiq::Testing.inline! { example.run }
  end

  describe '#process' do
    context 'with a tracking database entry' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact.id)
      end

      context 'with a file' do
        context 'when the delete succeeds' do
          it 'removes the tracking database entry' do
            expect { subject.process }.to change(Geo::JobArtifactRegistry, :count).by(-1)
          end

          it 'deletes the file' do
            expect { subject.process }.to change { File.exist?(job_artifact.file.path) }.from(true).to(false)
          end
        end

        context 'when the delete fails' do
          before do
            allow(File).to receive(:unlink).and_call_original
            allow(File).to receive(:unlink).with(job_artifact.file.path).and_raise(SystemCallError, "Cannot delete")
          end

          it 'does not remove the tracking database entry' do
            expect do
              expect { subject.process }.to raise_error(SystemCallError)
            end.not_to change(Geo::JobArtifactRegistry, :count)
          end
        end
      end

      context 'without a file' do
        before do
          FileUtils.rm(job_artifact.file.path)
        end

        it 'removes the tracking database entry' do
          expect { subject.process }.to change(Geo::JobArtifactRegistry, :count).by(-1)
        end
      end
    end

    context 'without a tracking database entry' do
      it 'does not create a tracking database entry' do
        expect { subject.process }.not_to change(Geo::JobArtifactRegistry, :count)
      end

      it 'does not delete the file (yet, due to possible race condition)' do
        expect { subject.process }.not_to change { File.exist?(job_artifact.file.path) }.from(true)
      end
    end
  end
end
