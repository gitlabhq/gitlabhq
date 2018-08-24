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

  describe '#shared_runners_minutes_limit_enabled?' do
    subject { job.shared_runners_minutes_limit_enabled? }

    context 'for shared runner' do
      before do
        job.runner = create(:ci_runner, :instance)
      end

      it do
        expect(job.project).to receive(:shared_runners_minutes_limit_enabled?)
          .and_return(true)

        is_expected.to be_truthy
      end
    end

    context 'with specific runner' do
      before do
        job.runner = create(:ci_runner, :project)
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

  build_artifacts_methods = {
    # has_codeclimate_json? is deprecated and replaced with code_quality_artifact (#5779)
    has_codeclimate_json?: {
      filename: Ci::Build::CODECLIMATE_FILE,
      job_names: %w[codeclimate codequality code_quality]
    },
    has_code_quality_json?: {
      filename: Ci::Build::CODE_QUALITY_FILE,
      job_names: %w[codeclimate codequality code_quality]
    },
    has_performance_json?: {
      filename: Ci::Build::PERFORMANCE_FILE,
      job_names: %w[performance deploy]
    },
    has_sast_json?: {
      filename: Ci::Build::SAST_FILE,
      job_names: %w[sast]
    },
    has_dependency_scanning_json?: {
      filename: Ci::Build::DEPENDENCY_SCANNING_FILE,
      job_names: %w[dependency_scanning]
    },
    has_license_management_json?: {
      filename: Ci::Build::LICENSE_MANAGEMENT_FILE,
      job_names: %w[license_management]
    },
    # has_sast_container_json? is deprecated and replaced with has_container_scanning_json (#5778)
    has_sast_container_json?: {
      filename: Ci::Build::SAST_CONTAINER_FILE,
      job_names: %w[sast:container container_scanning]
    },
    has_container_scanning_json?: {
      filename: Ci::Build::CONTAINER_SCANNING_FILE,
      job_names: %w[sast:container container_scanning]
    },
    has_dast_json?: {
      filename: Ci::Build::DAST_FILE,
      job_names: %w[dast]
    }
  }

  build_artifacts_methods.each do |method, requirements|
    filename = requirements[:filename]
    job_names = requirements[:job_names]

    describe "##{method}" do
      job_names.each do |job_name|
        context "with a job named #{job_name} and a file named #{filename}" do
          let(:build) do
            create(
              :ci_build,
              :artifacts,
              name: job_name,
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
      end

      context 'with an invalid filename' do
        let(:build) do
          create(
            :ci_build,
            :artifacts,
            name: job_names.first,
            pipeline: pipeline,
            options: {}
          )
        end

        it { expect(build.send(method)).to be_falsey }
      end

      context 'with an invalid job name' do
        let(:build) do
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

        it { expect(build.send(method)).to be_falsey }
      end
    end
  end
end
