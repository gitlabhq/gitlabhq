# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::LicenseComplianceJobsFinder do
  it_behaves_like ::Security::JobsFinder, described_class.allowed_job_types

  describe "#execute" do
    subject { finder.execute }

    let(:pipeline) { create(:ci_pipeline) }
    let(:finder) { described_class.new(pipeline: pipeline) }

    let!(:sast_build) { create(:ci_build, :sast, pipeline: pipeline) }
    let!(:container_scanning_build) { create(:ci_build, :container_scanning, pipeline: pipeline) }
    let!(:dast_build) { create(:ci_build, :dast, pipeline: pipeline) }
    let!(:license_scanning_build) { create(:ci_build, :license_scanning, pipeline: pipeline) }

    it 'returns only the license_scanning job' do
      is_expected.to contain_exactly(license_scanning_build)
    end
  end
end
