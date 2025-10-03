# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityJobsFinder, feature_category: :vulnerability_management do
  it_behaves_like ::Security::JobsFinder, described_class.allowed_job_types

  describe "#execute" do
    let_it_be(:pipeline) { create(:ci_pipeline) }
    let(:finder) { described_class.new(pipeline: pipeline) }

    subject { finder.execute }

    context 'with specific secure job types' do
      let!(:sast_build) { create(:ci_build, :sast, pipeline: pipeline) }
      let!(:container_scanning_build) { create(:ci_build, :container_scanning, pipeline: pipeline) }
      let!(:dast_build) { create(:ci_build, :dast, pipeline: pipeline) }
      let!(:secret_detection_build) { create(:ci_build, :secret_detection, pipeline: pipeline) }

      let(:finder) { described_class.new(pipeline: pipeline, job_types: [:sast, :container_scanning, :secret_detection]) }

      it 'returns only those requested' do
        is_expected.to include(sast_build)
        is_expected.to include(container_scanning_build)
        is_expected.to include(secret_detection_build)

        is_expected.not_to include(dast_build)
      end

      context 'with empty definition' do
        before_all do
          stub_feature_flags(stop_writing_builds_metadata: false)
        end

        let_it_be(:sast_build) { create(:ci_build, :without_job_definition, :sast, pipeline: pipeline) }
        let_it_be(:container_scanning_build) { create(:ci_build, :without_job_definition, :container_scanning, pipeline: pipeline) }
        let_it_be(:dast_build) { create(:ci_build, :without_job_definition, :dast, pipeline: pipeline) }
        let_it_be(:secret_detection_build) { create(:ci_build, :without_job_definition, :secret_detection, pipeline: pipeline) }

        let(:finder) { described_class.new(pipeline: pipeline, job_types: [:sast, :container_scanning, :secret_detection]) }

        it 'returns only those requested' do
          is_expected.to include(sast_build)
          is_expected.to include(container_scanning_build)
          is_expected.to include(secret_detection_build)

          is_expected.not_to include(dast_build)
        end

        context 'when ff read_from_new_ci_destinations is disabled' do
          before do
            stub_feature_flags(read_from_new_ci_destinations: false)
          end

          it 'returns only those requested' do
            is_expected.to include(sast_build)
            is_expected.to include(container_scanning_build)
            is_expected.to include(secret_detection_build)

            is_expected.not_to include(dast_build)
          end
        end
      end
    end

    context 'with combination of security jobs and license scanning jobs' do
      let!(:sast_build) { create(:ci_build, :sast, pipeline: pipeline) }
      let!(:container_scanning_build) { create(:ci_build, :container_scanning, pipeline: pipeline) }
      let!(:dast_build) { create(:ci_build, :dast, pipeline: pipeline) }
      let!(:secret_detection_build) { create(:ci_build, :secret_detection, pipeline: pipeline) }
      let!(:license_scanning_build) { create(:ci_build, :license_scanning, pipeline: pipeline) }

      it 'returns only the security jobs' do
        is_expected.to include(sast_build)
        is_expected.to include(container_scanning_build)
        is_expected.to include(dast_build)
        is_expected.to include(secret_detection_build)
        is_expected.not_to include(license_scanning_build)
      end
    end
  end
end
