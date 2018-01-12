require 'spec_helper'

describe Geo::JobArtifactDeletedEventStore do
  set(:secondary_node) { create(:geo_node) }
  let(:job_artifact) { create(:ci_job_artifact, :archive) }

  subject(:event_store) { described_class.new(job_artifact) }

  describe '#create' do
    it 'does not create an event when not running on a primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect { event_store.create }.not_to change(Geo::JobArtifactDeletedEvent, :count)
    end

    context 'when running on a primary node' do
      before do
        allow(Gitlab::Geo).to receive(:primary?) { true }
      end

      it 'does not create an event when LFS object is not on a local store' do
        allow(job_artifact).to receive(:local_store?).and_return(false)

        expect { event_store.create }.not_to change(Geo::JobArtifactDeletedEvent, :count)
      end

      it 'does not create an event when there are no secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { event_store.create }.not_to change(Geo::JobArtifactDeletedEvent, :count)
      end

      it 'creates a LFS object deleted event' do
        expect { event_store.create }.to change(Geo::JobArtifactDeletedEvent, :count).by(1)
      end

      it 'tracks LFS object attributes' do
        event_store.create

        event = Geo::JobArtifactDeletedEvent.last

        expect(event.job_artifact_id).to eq(job_artifact.id)
        expect(event.file_path).to match(%r{\A\h+/\h+/\h+/[\d_]+/\d+/\d+/ci_build_artifacts.zip\z})
      end

      it 'logs an error message when event creation fail' do
        invalid_job_artifact = create(:ci_job_artifact)
        event_store = described_class.new(invalid_job_artifact)

        expected_message = {
          class: "Geo::JobArtifactDeletedEventStore",
          job_artifact_id: invalid_job_artifact.id,
          file_path: nil,
          message: "Job artifact deleted event could not be created",
          error: "Validation failed: File path can't be blank"
        }

        expect(Gitlab::Geo::Logger).to receive(:error)
          .with(expected_message).and_call_original

        event_store.create
      end
    end
  end
end
