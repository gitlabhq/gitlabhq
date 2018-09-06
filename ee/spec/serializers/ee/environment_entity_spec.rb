# frozen_string_literal: true
require 'spec_helper'

describe EnvironmentEntity do
  using RSpec::Parameterized::TableSyntax

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:environment) { create(:environment, :with_review_app, ref: 'development', project: project) }
  let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

  let(:entity) do
    described_class.new(environment, request: double(current_user: user, project: project))
  end

  before do
    project.repository.add_branch(user, 'development', project.commit.id)
  end

  describe '#can_stop' do
    subject { entity.as_json[:can_stop] }

    it_behaves_like 'protected environments access'
  end

  describe '#terminal_path' do
    subject { entity.as_json.include?(:terminal_path) }

    before do
      allow(environment).to receive(:has_terminals?).and_return(true)
    end

    it_behaves_like 'protected environments access', false
  end

  describe 'security_reports hash' do
    it 'is present' do
      expect(entity.as_json.include?(:security_reports)).to eq(true)
    end

    it 'value :has_security_reports is false' do
      expect(entity.as_json[:security_reports].size).to eq(1)
      expect(entity.as_json[:security_reports]).to include(:has_security_reports)
      expect(entity.as_json[:security_reports][:has_security_reports]).to eq(false)
    end
  end

  context 'with secure artifacts' do
    let(:pipeline) { create(:ci_pipeline, :success, project: project) }
    let(:deployable) { create(:ci_build, :success, pipeline: pipeline) }

    jobs_parameters = [
      { name: 'sast', filename: Ci::Build::SAST_FILE },
      { name: 'dast', filename: Ci::Build::DAST_FILE },
      { name: 'container_scanning', filename: Ci::Build::CONTAINER_SCANNING_FILE },
      { name: 'dependency_scanning', filename: Ci::Build::DEPENDENCY_SCANNING_FILE }
    ]

    before do
      stub_licensed_features(sast: true, dast: true, dependency_scanning: true, sast_container: true)
      create(:deployment, deployable: deployable, environment: environment)

      jobs_parameters.each do |job_parameters|
        create(
          :ci_job_artifact,
          :archive,
          job: create(
            :ci_build,
            :success,
            pipeline: pipeline,
            name: job_parameters[:name],
            options: {
              artifacts: {
                paths: [job_parameters[:filename]]
              }
            }))
      end

      allow_any_instance_of(LegacyArtifactUploader).to receive(:exists?).and_return(true)
    end

    describe 'security_reports hash' do
      it 'contains the reports' do
        expect(entity.as_json[:security_reports]).to include(:sast_path)
        expect(entity.as_json[:security_reports]).to include(:dast_path)
        expect(entity.as_json[:security_reports]).to include(:container_scanning_path)
        expect(entity.as_json[:security_reports]).to include(:dependency_scanning_path)

        expect(entity.as_json[:security_reports][:sast_path]).to end_with(Ci::Build::SAST_FILE)
        expect(entity.as_json[:security_reports][:dast_path]).to end_with(Ci::Build::DAST_FILE)
        expect(entity.as_json[:security_reports][:container_scanning_path]).to end_with(Ci::Build::CONTAINER_SCANNING_FILE)
        expect(entity.as_json[:security_reports][:dependency_scanning_path]).to end_with(Ci::Build::DEPENDENCY_SCANNING_FILE)
      end

      it 'value :has_security_reports is true' do
        expect(entity.as_json[:security_reports]).to include(:has_security_reports)
        expect(entity.as_json[:security_reports][:has_security_reports]).to eq(true)
      end

      it 'contains link to latest pipeline' do
        expect(entity.as_json[:security_reports]).to include(:pipeline_security_path)
      end

      it 'contains link to vulnerability feedback' do
        expect(entity.as_json[:security_reports]).to include(:vulnerability_feedback_path)
      end
    end
  end
end
