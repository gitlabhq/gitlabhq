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

  describe 'secure_artifacts hash' do
    it 'is present' do
      expect(entity.as_json.include?(:secure_artifacts)).to eq(true)
    end

    it 'is empty' do
      expect(entity.as_json[:secure_artifacts].size).to eq(0)
    end
  end

  context 'with secure artifacts' do
    let(:pipeline) { create(:ci_pipeline, :success, project: project) }
    let(:deployable) { create(:ci_build, :success, pipeline: pipeline) }

    jobs_parameters = [
        { name: 'sast', filename: 'gl-sast-report.json' },
        { name: 'dast', filename: 'gl-dast-report.json' },
        { name: 'container_scanning', filename: 'gl-container-scanning-report.json' },
        { name: 'dependency_scanning', filename: 'gl-dependency-scanning-report.json' }
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
    end

    describe 'secure_artifacts hash' do
      it 'contains the reports' do
        allow_any_instance_of(LegacyArtifactUploader).to receive(:exists?).and_return(true)

        expect(entity.as_json[:secure_artifacts].size).to eq(4)

        expect(entity.as_json[:secure_artifacts]).to include(:sast_path)
        expect(entity.as_json[:secure_artifacts]).to include(:dast_path)
        expect(entity.as_json[:secure_artifacts]).to include(:container_scanning_path)
        expect(entity.as_json[:secure_artifacts]).to include(:dependency_scanning_path)

        expect(entity.as_json[:secure_artifacts][:sast_path]).to end_with(Ci::Build::SAST_FILE)
        expect(entity.as_json[:secure_artifacts][:dast_path]).to end_with(Ci::Build::DAST_FILE)
        expect(entity.as_json[:secure_artifacts][:container_scanning_path]).to end_with(Ci::Build::CONTAINER_SCANNING_FILE)
        expect(entity.as_json[:secure_artifacts][:dependency_scanning_path]).to end_with(Ci::Build::DEPENDENCY_SCANNING_FILE)
      end
    end
  end
end
