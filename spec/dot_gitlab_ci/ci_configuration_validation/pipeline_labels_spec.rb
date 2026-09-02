# frozen_string_literal: true

require 'spec_helper'
require_relative './shared_context_and_examples'

RSpec.describe 'CI configuration validation - branch pipelines', feature_category: :tooling do
  using RSpec::Parameterized::TableSyntax

  include ProjectForksHelper
  include CiConfigurationValidationHelper

  include_context 'with simulated pipeline attributes and shared project and user'
  include_context 'with simulated MR pipeline attributes'

  let(:pipeline_project) { gitlab_org_gitlab_project }
  let(:create_pipeline_service) { Ci::CreatePipelineService.new(target_project, user, ref: target_branch) }

  subject(:pipeline) do
    create_pipeline_service
      .execute(
        :push,
        dry_run: true,
        merge_request: merge_request,
        variables_attributes: mr_pipeline_variables_attributes
      ).payload
  end

  context 'when MR labeled with `pipeline:run-all-rspec` is changing app/models/user.rb' do
    let(:mr_labels) { ['pipeline:run-all-rspec'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'rspec-all frontend_fixture 1/8' }

    it_behaves_like 'merge request pipeline'
  end

  context 'when MR labeled with `pipeline:expedite pipeline::expedited` is changing app/models/user.rb' do
    let(:mr_labels) { ['pipeline:expedite', 'pipeline::expedited'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'setup-test-env' }

    it_behaves_like 'merge request pipeline'

    it_behaves_like 'merge train pipeline'
  end

  context 'when MR labeled with `pipeline::tier-1`' do
    let(:mr_labels) { ['pipeline::tier-1'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'pipeline-tier-1' }

    it_behaves_like 'merge request pipeline'
  end

  context 'when MR labeled with `pipeline::tier-2`' do
    let(:mr_labels) { ['pipeline::tier-2'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'pipeline-tier-2' }

    it_behaves_like 'merge request pipeline'
  end

  context 'when MR labeled with `pipeline::tier-3`' do
    let(:mr_labels) { ['pipeline::tier-3'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'pipeline-tier-3' }

    it_behaves_like 'merge request pipeline'
  end

  context 'with as-if-foss pipeline' do
    let(:changed_files) { ['app/models/user.rb'] }

    let(:mr_pipeline_variables_attributes) do
      super() << { key: 'AS_IF_FOSS_TOKEN', value: 'foss token' }
    end

    context 'when MR labeled with `pipeline::tier-3`' do
      let(:mr_labels) { ['pipeline::tier-3'] }
      let(:expected_job_name) { 'start-as-if-foss' }

      it_behaves_like 'merge request pipeline'
      it_behaves_like 'merge train pipeline'
    end

    context 'when MR labeled with `pipeline::tier-1`' do
      let(:mr_labels) { ['pipeline::tier-1'] }

      it "does not run as-if-foss pipeline" do
        expect(jobs).not_to include('start-as-if-foss')
      end
    end

    context 'when MR labeled with `pipeline:run-as-if-foss` and `pipeline::tier-1` labels' do
      let(:mr_labels) { ['pipeline:run-as-if-foss', 'pipeline::tier-3'] }
      let(:expected_job_name) { 'start-as-if-foss' }

      it "runs tier-1 as-if-foss pipeline" do
        expect(jobs).to include('start-as-if-foss')
      end
    end
  end

  context 'when MR labeled with `pipeline:force-run-as-if-jh` is changing app/models/user.rb' do
    let(:mr_labels) { ['pipeline:force-run-as-if-jh'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'start-as-if-jh' }

    let(:mr_pipeline_variables_attributes) do
      # workflow rule for "include", see .gitlab-ci.yml
      super() << { key: 'CI_PROJECT_URL', value: 'https://gitlab.com/gitlab-org/gitlab' }
    end

    it_behaves_like 'merge request pipeline'

    it_behaves_like 'merge train pipeline'
  end

  context 'when MR labeled with `pipeline:run-as-if-jh` and `pipeline::tier-2` is changing app/models/user.rb' do
    let(:mr_labels) { ['pipeline:run-as-if-jh', 'pipeline::tier-2'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'start-as-if-jh' }

    let(:mr_pipeline_variables_attributes) do
      base_attributes = super()
      # workflow rule for "include", see .gitlab-ci.yml
      base_attributes << { key: 'CI_PROJECT_URL', value: 'https://gitlab.com/gitlab-org/gitlab' }
      base_attributes << { key: 'CI_AS_IF_JH_ENABLED', value: 'true' }
    end

    it_behaves_like 'merge request pipeline'

    it_behaves_like 'merge train pipeline'
  end

  context 'when MR labeled with `pipeline:run-with-ruby-next` is changing app/models/user.rb' do
    let(:mr_labels) { ['pipeline:run-with-ruby-next'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'e2e-test-pipeline-generate' }

    it_behaves_like 'merge request pipeline'

    it_behaves_like 'merge train pipeline'
  end

  context 'when MR labeled with `pipeline:run-in-ruby3_3` is changing app/models/user.rb' do
    let(:mr_labels) { ['pipeline:run-in-ruby3_3'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'e2e-test-pipeline-generate' }

    it_behaves_like 'merge request pipeline'

    it_behaves_like 'merge train pipeline'
  end

  describe 'Ruby version resolution' do
    let(:changed_files) { ['app/models/user.rb'] }

    # Override both version variables so the assertions distinguish default
    # from next even when the repo values are momentarily equal.
    let(:mr_pipeline_variables_attributes) do
      base_attributes = super()
      base_attributes << { key: 'RUBY_VERSION_DEFAULT', value: '3.98.8' }
      base_attributes << { key: 'RUBY_VERSION_NEXT', value: '3.99.9' }
    end

    def resolved_ruby_version(job_name)
      expect(pipeline.yaml_errors).to be_nil
      expect(pipeline.errors).to be_empty

      job = pipeline.stages.flat_map(&:statuses).find { |status| status.name == job_name }

      raise ArgumentError, "job #{job_name} not found in pipeline" unless job

      job.scoped_variables.sort_and_expand_all['RUBY_VERSION']&.value
    end

    context 'when the MR labels keep the default Ruby version' do
      where(:case_name, :mr_labels) do
        'unlabelled'             | []
        'database'               | ['database']
        'Community contribution' | ['Community contribution']
        'rails-next label'       | ['pipeline:run-with-rails-next']
      end

      with_them do
        it 'resolves RUBY_VERSION to RUBY_VERSION_DEFAULT' do
          expect(resolved_ruby_version('setup-test-env')).to eq('3.98.8')
        end
      end
    end

    context 'when MR is labeled with `pipeline:run-with-ruby-next`' do
      let(:mr_labels) { ['pipeline:run-with-ruby-next'] }

      it 'resolves RUBY_VERSION to RUBY_VERSION_NEXT' do
        expect(resolved_ruby_version('setup-test-env')).to eq('3.99.9')
      end

      context 'when the pipeline runs on a merge train' do
        let(:ci_merge_request_event_type) { 'merge_train' }

        it 'resolves RUBY_VERSION to RUBY_VERSION_DEFAULT' do
          expect(resolved_ruby_version('pre-merge-checks')).to eq('3.98.8')
        end
      end

      context 'with an as-if-foss pipeline' do
        let(:mr_labels) { ['pipeline:run-with-ruby-next', 'pipeline::tier-3'] }

        let(:mr_pipeline_variables_attributes) do
          super() << { key: 'AS_IF_FOSS_TOKEN', value: 'foss token' }
        end

        it 'forwards RUBY_VERSION_NEXT to the as-if-foss child pipeline' do
          expect(resolved_ruby_version('start-as-if-foss')).to eq('3.99.9')
        end
      end
    end
  end
end
