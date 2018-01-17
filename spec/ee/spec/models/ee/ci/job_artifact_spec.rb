require 'spec_helper'

describe EE::Ci::JobArtifact do
  describe '#destroy' do
    set(:primary) { create(:geo_node, :primary) }
    set(:secondary) { create(:geo_node) }

    it 'creates a JobArtifactDeletedEvent' do
      job_artifact = create(:ci_job_artifact, :archive)

      expect do
        job_artifact.destroy
      end.to change { Geo::JobArtifactDeletedEvent.count }.by(1)
    end
  end
end
