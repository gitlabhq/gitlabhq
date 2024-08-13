# frozen_string_literal: true

require 'spec_helper'

# ***********************************************************************************************************
# The tests in this file are recommended to run locally to test ci configuration changes
# The tests are slow because pipeline simuation takes time given our current pipeline yaml size
# ***********************************************************************************************************
# TEST COVERAGE
#
# GitLab.com gitlab-org/gitlab-foss Project
#    Master Pipeline Triggered by Push
#    Scheduled Master Pipeline
#
# GitLab.com gitlab-org/gitlab Master Pipeline
#   Default Master Pipeline Triggered by Push
#   Scheduled pipeline - Nightly
#   Scheduled pipeline - Maintenance
#
# Merge Request Pipeline (and merge train pipeline under the same contexts)
#   Unlabeled MR Changing GITALY_SERVER_VERSION
#   Unlabeled MR Changing Dangerfile, .gitlab/ci/frontend.gitlab-ci.yml
#
#   MR Labeled with pipeline:run-all-rspec Changing app/models/user.rb
#   MR Labeled with pipeline:expedite pipeline::expedited Changing app/models/user.rb
#   MR Labeled with pipeline::tier-1 Changing app/models/user.rb
#   MR Labeled with pipeline::tier-2 and pipeline:mr-approved Changing app/models/user.rb
#   MR Labeled with pipeline::tier-3 and pipeline:mr-approved Changing app/models/user.rb
#   MR Labeled with pipeline:run-as-if-foss Changing app/models/user.rb
#
# Automated MR
#   MR Created from release-tools/update-gitaly Source Branch Changing GITALY_SERVER_VERSION
#
# Stable Branch
#   MR Targeting a Stable Branch Changing app/models/user.rb
#
# Fork Project MRs
#   MR Created from a Fork Project Master Branch Changing package.json
#   MR Created from a Fork Project Feature Branch Changing package.json
# ***********************************************************************************************************
# CONTRIBUTE
#
# If you think we are missing coverage for an important pipeline type, please add them.
#
# For example, ci rule changes could break gitlab-foss pipelines, as seen in
# https://gitlab.com/gitlab-org/quality/engineering-productivity/master-broken-incidents/-/issues/7356
# we then added test cases by simulating pipeline for gitlab-org/gitlab-foss
# See `with gitlab.com gitlab-org gitlab-foss project` context below for details.
# ***********************************************************************************************************
RSpec.describe 'ci jobs dependency', feature_category: :tooling do
  include ProjectForksHelper

  def sync_local_files_to_project(project, user, branch_name, files:)
    actions = []

    entries = project.repository.tree(branch_name, recursive: true).entries
    entries.map! { |e| e.dir? ? project.repository.tree(branch_name, e.path, recursive: true).entries : e }
    current_files = entries.flatten.select(&:file?).map(&:path).uniq

    # Delete old
    actions.concat (current_files - files).map { |file| { action: :delete, file_path: file } }
    # Add new
    actions.concat (files - current_files).map { |file|
                     { action: :create, file_path: file, content: read_file(file) }
                   }

    # Update changed
    (current_files & files).each do |file|
      content = read_file(file)
      if content != project.repository.blob_data_at(branch_name, file)
        actions << { action: :update, file_path: file, content: content }
      end
    end

    if actions.any?
      puts "Syncing files to #{project.full_path} #{branch_name} branch"
      project.repository.commit_files(user, branch_name: branch_name, message: 'syncing', actions: actions)
    else
      puts "No file syncing needed"
    end
  end

  def read_file(file, ignore_ci_component: true)
    content = File.read(file)

    return content unless ignore_ci_component

    fake_job = <<~YAML
    .ignore:
      script: echo ok
    YAML

    file.end_with?('.yml') && %r{^\s*- component:.*CI_SERVER_}.match?(content) ? fake_job : content
  end

  let(:ci_server_host) { 'gitlab.com' }
  let(:ci_project_namespace) { 'gitlab-org' }
  let(:ci_project_path) { 'gitlab-org/gitlab' }
  let(:ci_project_name) { 'gitlab' }
  let(:ci_pipeline_source) { 'push' }
  let(:ci_commit_branch) { master_branch }

  let(:variables_attributes_base) do
    [
      { key: 'CI_SERVER_HOST', value: ci_server_host },
      { key: 'CI_PROJECT_NAMESPACE', value: ci_project_namespace },
      { key: 'CI_PROJECT_PATH', value: ci_project_path },
      { key: 'CI_PROJECT_NAME', value: ci_project_name },
      { key: 'CI_PIPELINE_SOURCE', value: ci_pipeline_source },
      { key: 'CI_COMMIT_BRANCH', value: ci_commit_branch }
    ]
  end

  let_it_be(:group) { create(:group, path: 'gitlab-org') }
  let_it_be(:gitlab_org_gitlab_project) { create(:project, :empty_repo, group: group, path: 'gitlab') }
  let_it_be(:user) { create(:user) }
  let_it_be(:ci_glob) { Dir.glob("{.gitlab-ci.yml,.gitlab/**/*.yml}").freeze }
  let_it_be(:master_branch) { 'master' }

  let(:create_pipeline_service) { Ci::CreatePipelineService.new(gitlab_org_gitlab_project, user, ref: master_branch) }
  let(:jobs) { pipeline.stages.flat_map { |s| s.statuses.map(&:name) } }

  around do |example|
    with_net_connect_allowed { example.run } # creating pipeline requires network call to fetch templates
  end

  before_all do
    gitlab_org_gitlab_project.add_developer(user)

    sync_local_files_to_project(
      gitlab_org_gitlab_project,
      user,
      master_branch,
      files: ci_glob
    )
  end

  before do
    # delete once we have a migration to permanently increase limit
    stub_application_setting(max_yaml_size_bytes: 2.megabytes)
  end

  shared_examples 'master pipeline' do
    let(:content) do
      gitlab_org_gitlab_project.repository.blob_at(master_branch, '.gitlab-ci.yml').data
    end

    subject(:pipeline) do
      trigger_source = ci_pipeline_source.to_sym
      create_pipeline_service
        .execute(trigger_source, dry_run: true, content: content, variables_attributes: variables_attributes)
        .payload
    end

    it 'is valid' do
      expect(pipeline.yaml_errors).to be nil
      expect(pipeline.status).to eq('created')
      expect(jobs).to include(expected_job_name)
    end
  end

  context 'with gitlab.com gitlab-org/gitlab master pipeline' do
    context 'with default master pipeline' do
      let(:variables_attributes) { variables_attributes_base }
      let(:expected_job_name) { 'db:migrate:multi-version-upgrade' }

      # Test: remove rules from .rails:rules:setup-test-env
      it_behaves_like 'master pipeline'
    end

    context 'with scheduled nightly' do
      let(:ci_pipeline_source) { 'schedule' }
      let(:expected_job_name) { 'db:rollback single-db' }
      let(:variables_attributes) do
        [
          *variables_attributes_base,
          { key: 'SCHEDULE_TYPE', value: 'nightly' }
        ]
      end

      # .if-default-branch-schedule-nightly
      # included in .qa:rules:package-and-test-ce
      # used by e2e:package-and-test-ce
      # needs e2e-test-pipeline-generate
      # has rule .qa:rules:determine-e2e-tests

      # Test: I can remove this rule from .qa:rules:determine-e2e-tests
      # - <<: *if-dot-com-gitlab-org-schedule
      #   allow_failure: true
      it_behaves_like 'master pipeline'
    end

    context 'with scheduled maintenance' do
      let(:ci_pipeline_source) { 'schedule' }
      let(:expected_job_name) { 'generate-frontend-fixtures-mapping' }
      let(:variables_attributes) do
        [
          *variables_attributes_base,
          { key: 'SCHEDULE_TYPE', value: 'maintenance' }
        ]
      end

      it_behaves_like 'master pipeline'
    end
  end

  context 'with gitlab.com gitlab-org gitlab-foss project' do
    let(:ci_project_name) { 'gitlab-foss' }
    let(:ci_project_path) { 'gitlab-org/gitlab-foss' }
    let(:variables_attributes) { variables_attributes_base }

    context 'with master pipeline triggered by push' do
      let(:expected_job_name) { 'db:backup_and_restore single-db' }

      it_behaves_like 'master pipeline'
    end

    context 'with scheduled master pipeline' do
      let(:ci_pipeline_source) { 'schedule' }
      let(:expected_job_name) { 'db:backup_and_restore single-db' }

      # Verify by removing the following rule from .qa:rules:e2e:test-on-cng
      # - !reference [".qa:rules:package-and-test-never-run", rules]
      it_behaves_like 'master pipeline'
    end
  end

  context 'with MR pipeline' do
    let(:ci_pipeline_source) { 'merge_request_event' }
    let(:ci_merge_request_event_type) { 'merged_result' }
    let(:ci_commit_branch) { target_branch } # to simulate merged results pipeline
    let(:ci_merge_request_labels_string) { '' }

    let(:mr_pipeline_variables_attributes) do
      [
        *variables_attributes_base,
        { key: 'CI_MERGE_REQUEST_EVENT_TYPE', value: ci_merge_request_event_type },
        { key: 'CI_MERGE_REQUEST_LABELS', value: ci_merge_request_labels_string }
      ]
    end

    let(:create_pipeline_service) { Ci::CreatePipelineService.new(target_project, user, ref: target_branch) }

    let(:source_project) { gitlab_org_gitlab_project }
    let(:target_project) { gitlab_org_gitlab_project }
    let(:source_branch) { "feature_branch_ci_#{SecureRandom.uuid}" }
    let(:target_branch) { master_branch }

    let(:merge_request) do
      create(:merge_request,
        source_project: source_project,
        source_branch: source_branch,
        target_project: target_project,
        target_branch: target_branch
      )
    end

    subject(:pipeline) do
      create_pipeline_service
        .execute(
          :push,
          dry_run: true,
          merge_request: merge_request,
          variables_attributes: mr_pipeline_variables_attributes
        ).payload
    end

    before do
      file_change_actions = changed_files.map do |file_path|
        action = source_project.repository.blob_at(source_branch, file_path).nil? ? :create : :update
        {
          action: action,
          file_path: file_path,
          content: 'content'
        }
      end

      source_project.repository.commit_files(
        user,
        branch_name: source_branch,
        message: 'changes files',
        actions: file_change_actions
      )
    end

    after do
      source_project.repository.delete_branch(source_branch)
    end

    shared_examples 'merge request pipeline' do
      it "succeeds with expected job" do
        expect(pipeline.yaml_errors).to be nil
        expect(pipeline.status).to eq('created')
        # to confirm that the dependent job is actually created and rule out false positives
        expect(jobs).to include(expected_job_name)
      end
    end

    shared_examples 'merge train pipeline' do
      let(:ci_merge_request_event_type) { 'merge_train' }

      it "succeeds with expected job" do
        expect(pipeline.yaml_errors).to be nil
        expect(pipeline.status).to eq('created')
        expect(jobs).to include('pre-merge-checks')
        expect(jobs).not_to include('upload-frontend-fixtures')
      end
    end

    # gitaly, db, backend patterns
    context "when unlabeled MR is changing GITALY_SERVER_VERSION" do
      let(:changed_files) { ['GITALY_SERVER_VERSION'] }
      let(:expected_job_name) { 'eslint' }

      it_behaves_like 'merge request pipeline'

      it_behaves_like 'merge train pipeline'
    end

    # Test: remove the following rules from `.frontend:rules:default-frontend-jobs`:
    #   - <<: *if-default-refs
    #     changes: *code-backstage-patterns
    context 'when unlabled MR is changing Dangerfile, .gitlab/ci/frontend.gitlab-ci.yml' do
      let(:changed_files) { ['Dangerfile', '.gitlab/ci/frontend.gitlab-ci.yml'] }
      let(:expected_job_name) { 'rspec-all frontend_fixture 1/7' }

      it_behaves_like 'merge request pipeline'
    end

    # Test: remove the following rules from `.frontend:rules:default-frontend-jobs`:
    # - <<: *if-merge-request-labels-run-all-rspec
    context 'when MR labeled with `pipeline:run-all-rspec` is changing app/models/user.rb' do
      let(:ci_merge_request_labels_string) { 'pipeline:run-all-rspec' }
      let(:changed_files) { ['app/models/user.rb'] }
      let(:expected_job_name) { 'rspec-all frontend_fixture 1/7' }

      it_behaves_like 'merge request pipeline'
    end

    # code-patterns, code-backstage-patterns, backend patterns, code-qa-patterns
    context 'when MR labeled with `pipeline:expedite pipeline::expedited` is changing app/models/user.rb' do
      let(:ci_merge_request_labels_string) { 'pipeline:expedite pipeline::expedited' }
      let(:changed_files) { ['app/models/user.rb'] }
      let(:expected_job_name) { 'setup-test-env' }

      it_behaves_like 'merge request pipeline'

      it_behaves_like 'merge train pipeline'
    end

    context 'when MR labeled with `pipeline::tier-1`' do
      let(:ci_merge_request_labels_string) { 'pipeline::tier-1' }
      let(:changed_files) { ['app/models/user.rb'] }
      let(:expected_job_name) { 'pipeline-tier-1' }

      it_behaves_like 'merge request pipeline'
    end

    context 'when MR labeled with `pipeline::tier-2` and `pipeline:mr-approved`' do
      let(:ci_merge_request_labels_string) { 'pipeline::tier-2 pipeline:mr-approved' }
      let(:changed_files) { ['app/models/user.rb'] }
      let(:expected_job_name) { 'pipeline-tier-2' }

      it_behaves_like 'merge request pipeline'
    end

    context 'when MR labeled with `pipeline::tier-3` and `pipeline:mr-approved`' do
      let(:ci_merge_request_labels_string) { 'pipeline::tier-3 pipeline:mr-approved' }
      let(:changed_files) { ['app/models/user.rb'] }
      let(:expected_job_name) { 'pipeline-tier-3' }

      it_behaves_like 'merge request pipeline'
    end

    context 'when MR labeled with `pipeline:run-as-if-foss` is changing app/models/user.rb' do
      let(:ci_merge_request_labels_string) { 'pipeline:run-as-if-foss' }
      let(:changed_files) { ['app/models/user.rb'] }
      let(:expected_job_name) { 'start-as-if-foss' }

      let(:mr_pipeline_variables_attributes) do
        super() << { key: 'AS_IF_FOSS_TOKEN', value: 'foss token' }
      end

      it_behaves_like 'merge request pipeline'

      it_behaves_like 'merge train pipeline'
    end

    context 'when MR is created from "release-tools/update-gitaly" source branch' do
      let(:source_branch) { 'release-tools/update-gitaly' }
      let(:changed_files) { ['GITALY_SERVER_VERSION'] }
      let(:expected_job_name) { 'update-gitaly-binaries-cache' }

      it_behaves_like 'merge request pipeline'
    end

    # Reminder, we are NOT verifying the CI config from the remote stable branch
    # This test just mocks the target branch name to be a stable branch
    # the tested config is what's currently in the local .gitlab/ci folders

    # Test: remove the following rules from `.frontend:rules:default-frontend-jobs`:
    #   - <<: *if-default-refs
    #     changes: *code-backstage-patterns
    context 'when MR targeting a stable branch is changing app/models/user.rb' do
      let(:target_branch)     { '16-10-stable-ee' }
      let(:changed_files)     { ['app/models/user.rb'] }
      let(:expected_job_name) { 'rspec-all frontend_fixture 1/7' }

      before do
        sync_local_files_to_project(
          target_project,
          user,
          target_branch,
          files: ci_glob
        )
      end

      after do
        target_project.repository.delete_branch(target_branch)
      end

      it_behaves_like 'merge request pipeline'

      it_behaves_like 'merge train pipeline'
    end

    context 'with fork project MRs' do
      let_it_be(:fork_project_mr_source) { fork_project(gitlab_org_gitlab_project, user, repository: true) }
      let(:source_project)    { fork_project_mr_source }
      let(:target_project)    { gitlab_org_gitlab_project }

      context 'when MR is created from a fork project master branch' do
        let(:source_branch)     { master_branch }
        let(:target_branch)     { master_branch }
        let(:changed_files)     { ['package.json'] }
        let(:expected_job_name) { 'rspec-all frontend_fixture 1/7' }

        context 'when running MR pipeline in the context of the fork project' do
          let(:ci_project_namespace) { fork_project_mr_source.namespace.full_path }
          let(:ci_project_path)      { fork_project_mr_source.full_path }
          let(:ci_project_name)      { fork_project_mr_source.name }

          it_behaves_like 'merge request pipeline'
        end

        context 'when running MR pipeline in the context of canonical project' do
          it_behaves_like 'merge request pipeline'
        end

        it_behaves_like 'merge train pipeline'
      end

      context 'when MR is created from a fork project feature branch' do
        let(:source_branch)     { "feature_branch_ci_#{SecureRandom.uuid}" }
        let(:target_branch)     { master_branch }
        let(:changed_files)     { ['package.json'] }
        let(:expected_job_name) { 'rspec-all frontend_fixture 1/7' }

        context 'when running MR pipeline in the context of the fork project' do
          let(:ci_project_namespace) { fork_project_mr_source.namespace.full_path }
          let(:ci_project_path)      { fork_project_mr_source.full_path }
          let(:ci_project_name)      { fork_project_mr_source.name }

          it_behaves_like 'merge request pipeline'
        end

        context 'when running MR pipeline in the context of canonical project' do
          it_behaves_like 'merge request pipeline'
        end

        it_behaves_like 'merge train pipeline'
      end
    end
  end
end
