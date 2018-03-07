require 'spec_helper'

describe Ci::Pipeline do
  let(:user) { create(:user) }
  set(:project) { create(:project) }

  let(:pipeline) do
    create(:ci_empty_pipeline, status: :created, project: project)
  end

  it { is_expected.to have_one(:chat_data) }

  describe '.failure_reasons' do
    it 'contains failure reasons about exceeded limits' do
      expect(described_class.failure_reasons)
        .to include 'activity_limit_exceeded', 'size_limit_exceeded'
    end
  end

  ARTIFACTS_METHODS = {
    codeclimate_artifact: [Ci::Build::CODEQUALITY_FILE, 'codequality'],
    performance_artifact: [Ci::Build::PERFORMANCE_FILE, 'performance'],
    sast_artifact: [Ci::Build::SAST_FILE, 'sast'],
    sast_container_artifact: [Ci::Build::SAST_CONTAINER_FILE, 'sast:container'],
    dast_artifact: [Ci::Build::DAST_FILE, 'dast']
  }.freeze

  ARTIFACTS_METHODS.each do |method, options|
    describe method.to_s do
      context 'has corresponding job' do
        let!(:build) do
          filename, name = options

          create(
            :ci_build,
            :artifacts,
            name: name,
            pipeline: pipeline,
            options: {
              artifacts: {
                paths: [filename]
              }
            }
          )
        end

        it { expect(pipeline.send(method)).to eq(build) }
      end

      context 'no codequality job' do
        before do
          create(:ci_build, pipeline: pipeline)
        end

        it { expect(pipeline.send(method)).to be_nil }
      end
    end
  end
end
