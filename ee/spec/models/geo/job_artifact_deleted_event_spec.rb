require 'spec_helper'

RSpec.describe Geo::JobArtifactDeletedEvent, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:job_artifact) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:job_artifact) }
  end
end
