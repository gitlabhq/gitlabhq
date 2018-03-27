require 'spec_helper'

describe Ci::Build do
  set(:group) { create(:group, :access_requestable, plan: :bronze_plan) }
  let(:project) { create(:project, :repository, group: group) }

  let(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: project.commit.id,
                         ref: project.default_branch,
                         status: 'success')
  end

  let(:job) { create(:ci_build, pipeline: pipeline) }

  describe '.codequality' do
    subject { described_class.codequality }

    context 'when a job name is codequality' do
      let!(:job) { create(:ci_build, pipeline: pipeline, name: 'codequality') }

      it { is_expected.to include(job) }
    end

    context 'when a job name is codeclimate' do
      let!(:job) { create(:ci_build, pipeline: pipeline, name: 'codeclimate') }

      it { is_expected.to include(job) }
    end

    context 'when a job name is irrelevant' do
      let!(:job) { create(:ci_build, pipeline: pipeline, name: 'codechecker') }

      it { is_expected.not_to include(job) }
    end
  end

  describe '#shared_runners_minutes_limit_enabled?' do
    subject { job.shared_runners_minutes_limit_enabled? }

    context 'for shared runner' do
      before do
        job.runner = create(:ci_runner, :shared)
      end

      it do
        expect(job.project).to receive(:shared_runners_minutes_limit_enabled?)
          .and_return(true)

        is_expected.to be_truthy
      end
    end

    context 'with specific runner' do
      before do
        job.runner = create(:ci_runner, :specific)
      end

      it { is_expected.to be_falsey }
    end

    context 'without runner' do
      it { is_expected.to be_falsey }
    end
  end

  context 'updates pipeline minutes' do
    let(:job) { create(:ci_build, :running, pipeline: pipeline) }

    %w(success drop cancel).each do |event|
      it "for event #{event}" do
        expect(UpdateBuildMinutesService)
          .to receive(:new).and_call_original

        job.public_send(event)
      end
    end
  end

  describe '#stick_build_if_status_changed' do
    it 'sticks the build if the status changed' do
      job = create(:ci_build, :pending)

      allow(Gitlab::Database::LoadBalancing).to receive(:enable?)
        .and_return(true)

      expect(Gitlab::Database::LoadBalancing::Sticking).to receive(:stick)
        .with(:build, job.id)

      job.update(status: :running)
    end
  end

  describe '#variables' do
    subject { job.variables }

    context 'when environment specific variable is defined' do
      let(:environment_varialbe) do
        { key: 'ENV_KEY', value: 'environment', public: false }
      end

      before do
        job.update(environment: 'staging')
        create(:environment, name: 'staging', project: job.project)

        variable =
          build(:ci_variable,
                environment_varialbe.slice(:key, :value)
                  .merge(project: project, environment_scope: 'stag*'))

        variable.save!
      end

      context 'when variable environment scope is available' do
        before do
          stub_licensed_features(variable_environment_scope: true)
        end

        it { is_expected.to include(environment_varialbe) }
      end

      context 'when variable environment scope is not available' do
        before do
          stub_licensed_features(variable_environment_scope: false)
        end

        it { is_expected.not_to include(environment_varialbe) }
      end

      context 'when there is a plan for the group' do
        it 'GITLAB_FEATURES should include the features for that plan' do
          is_expected.to include({ key: 'GITLAB_FEATURES', value: anything, public: true })
          features_variable = subject.find { |v| v[:key] == 'GITLAB_FEATURES' }
          expect(features_variable[:value]).to include('multiple_ldap_servers')
        end
      end
    end
  end

  BUILD_ARTIFACTS_METHODS = {
    has_codeclimate_json?: Ci::Build::CODEQUALITY_FILE,
    has_performance_json?: Ci::Build::PERFORMANCE_FILE,
    has_sast_json?: Ci::Build::SAST_FILE,
    has_dependency_scanning_json?: Ci::Build::DEPENDENCY_SCANNING_FILE,
    has_sast_container_json?: Ci::Build::SAST_CONTAINER_FILE,
    has_dast_json?: Ci::Build::DAST_FILE
  }.freeze

  BUILD_ARTIFACTS_METHODS.each do |method, filename|
    describe "##{method}" do
      context 'valid build' do
        let!(:build) do
          create(
            :ci_build,
            :artifacts,
            pipeline: pipeline,
            options: {
              artifacts: {
                paths: [filename, 'some-other-artifact.txt']
              }
            }
          )
        end

        it { expect(build.send(method)).to be_truthy }
      end

      context 'invalid build' do
        let!(:build) do
          create(
            :ci_build,
            :artifacts,
            pipeline: pipeline,
            options: {}
          )
        end

        it { expect(build.send(method)).to be_falsey }
      end
    end
  end
end
