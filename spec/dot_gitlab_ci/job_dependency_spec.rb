# frozen_string_literal: true

require 'spec_helper'

# ***********************************************************************************************************
# The tests in this file are recommended to run locally to test ci configuration changes
# The test runs quite slowly because our configuration logic is very complex and it takes time to process
# ***********************************************************************************************************
#
# HOW TO CONTRIBUTE
#
# For example, ci rule changes could break gitlab-foss pipelines, as seen in
# https://gitlab.com/gitlab-org/quality/engineering-productivity/master-broken-incidents/-/issues/7356
# we then added test cases by simulating pipeline for gitlab-org/gitlab-foss
# See `with gitlab.com gitlab-org gitlab-foss project` context below for details.
# If you think we are missing important test cases for a pipeline type, please add them following this exmaple.
# ***********************************************************************************************************
RSpec.describe 'ci jobs dependency', feature_category: :tooling,
  quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/34040#note_1991033499' do
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
      puts "Syncing files to #{branch_name} branch"
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

  let_it_be(:group)   { create(:group, path: 'ci-org') }
  let_it_be(:user)    { create(:user) }
  let_it_be(:project) { create(:project, :empty_repo, group: group, path: 'ci') }
  let_it_be(:ci_glob) { Dir.glob("{.gitlab-ci.yml,.gitlab/**/*.yml}").freeze }
  let_it_be(:master_branch) { 'master' }

  let(:gitlab_com_variables_attributes_base) do
    [
      { key: 'CI_SERVER_HOST', value: 'gitlab.com' },
      { key: 'CI_PROJECT_NAMESPACE', value: 'gitlab-org' },
      { key: 'CI_PROJECT_PATH', value: 'gitlab-org/gitlab' },
      { key: 'CI_PROJECT_NAME', value: 'gitlab' }
    ]
  end

  let(:create_pipeline_service) { Ci::CreatePipelineService.new(project, user, ref: master_branch) }
  let(:jobs) { pipeline.stages.flat_map { |s| s.statuses.map(&:name) } }

  around(:all) do |example|
    with_net_connect_allowed { example.run } # creating pipeline requires network call to fetch templates
  end

  before_all do
    project.add_developer(user)

    sync_local_files_to_project(
      project,
      user,
      master_branch,
      files: ci_glob
    )
  end

  shared_examples 'master pipeline' do
    let(:content) do
      project.repository.blob_at(master_branch, '.gitlab-ci.yml').data
    end

    subject(:pipeline) do
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
      let(:variables_attributes) { gitlab_com_variables_attributes_base }
      let(:trigger_source) { :push }
      let(:expected_job_name) { 'db:migrate:multi-version-upgrade' }

      # Test: remove rules from .rails:rules:setup-test-env
      it_behaves_like 'master pipeline'
    end

    context 'with scheduled nightly' do
      let(:trigger_source) { :schedule }
      let(:expected_job_name) { 'db:rollback single-db' }
      let(:variables_attributes) do
        [
          *gitlab_com_variables_attributes_base,
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
      let(:trigger_source) { :schedule }
      let(:expected_job_name) { 'generate-frontend-fixtures-mapping' }
      let(:variables_attributes) do
        [
          *gitlab_com_variables_attributes_base,
          { key: 'SCHEDULE_TYPE', value: 'maintenance' }
        ]
      end

      it_behaves_like 'master pipeline'
    end
  end

  context 'with gitlab.com gitlab-org gitlab-foss project' do
    let(:variables_attributes) do
      [
        { key: 'CI_SERVER_HOST', value: 'gitlab.com' },
        { key: 'CI_PROJECT_NAMESPACE', value: 'gitlab-org' },
        { key: 'CI_PROJECT_PATH', value: 'gitlab-org/gitlab-foss' },
        { key: 'CI_PROJECT_NAME', value: 'gitlab-foss' }
      ]
    end

    context 'with master pipeline triggered by push' do
      let(:trigger_source) { :push }
      let(:expected_job_name) { 'db:backup_and_restore single-db' }

      it_behaves_like 'master pipeline'
    end

    context 'with scheduled master pipeline' do
      let(:trigger_source) { :schedule }
      let(:expected_job_name) { 'db:backup_and_restore single-db' }

      # Verify by removing the following rule from .qa:rules:e2e:test-on-cng
      # - !reference [".qa:rules:package-and-test-never-run", rules]
      it_behaves_like 'master pipeline'
    end
  end

  context 'with MR pipeline' do
    let(:mr_pipeline_variables_attributes_base) do
      [
        *gitlab_com_variables_attributes_base,
        { key: 'CI_MERGE_REQUEST_EVENT_TYPE', value: 'merged_result' },
        { key: 'CI_COMMIT_BRANCH', value: master_branch }
      ]
    end

    let(:source_branch) { "feature_branch_ci_#{SecureRandom.uuid}" }
    let(:target_branch) { master_branch }

    let(:merge_request) do
      create(:merge_request,
        source_project: project,
        source_branch: source_branch,
        target_project: project,
        target_branch: target_branch
      )
    end

    shared_examples 'merge request pipeline' do
      let(:variables_attributes) do
        [
          *mr_pipeline_variables_attributes_base,
          { key: 'CI_MERGE_REQUEST_LABELS', value: labels_string }
        ]
      end

      subject(:pipeline) do
        create_pipeline_service
          .execute(:push, dry_run: true, merge_request: merge_request, variables_attributes: variables_attributes)
          .payload
      end

      before do
        actions = changed_files.map do |file_path|
          {
            action: :create,
            file_path: file_path,
            content: 'content'
          }
        end

        project.repository.commit_files(
          user,
          branch_name: source_branch,
          message: 'changes files',
          actions: actions
        )
      end

      after do
        project.repository.delete_branch(source_branch)
      end

      it "creates a valid pipeline with expected job" do
        expect(pipeline.yaml_errors).to be nil
        expect(pipeline.status).to eq('created')
        # to confirm that the dependent job is actually created and rule out false positives
        expect(jobs).to include(expected_job_name)
      end
    end

    # gitaly, db, backend patterns
    context "when unlabeled MR is changing GITALY_SERVER_VERSION" do
      let(:labels_string) { '' }
      let(:changed_files) { ['GITALY_SERVER_VERSION'] }
      let(:expected_job_name) { 'eslint' }

      it_behaves_like 'merge request pipeline'
    end

    # Test: remove the following rules from `.frontend:rules:default-frontend-jobs`:
    #   - <<: *if-default-refs
    #     changes: *code-backstage-patterns
    context 'when unlabled MR is changing Dangerfile, .gitlab/ci/frontend.gitlab-ci.yml' do
      let(:labels_string) { '' }
      let(:changed_files) { ['Dangerfile', '.gitlab/ci/frontend.gitlab-ci.yml'] }
      let(:expected_job_name) { 'rspec-all frontend_fixture 1/7' }

      it_behaves_like 'merge request pipeline'
    end

    # Test: remove the following rules from `.frontend:rules:default-frontend-jobs`:
    # - <<: *if-merge-request-labels-run-all-rspec
    context 'when MR labeled with `pipeline:run-all-rspec` is changing keeps/quarantine-test.rb' do
      let(:labels_string) { 'pipeline:run-all-rspec' }
      let(:changed_files) { ['keeps/quarantine-test.rb'] }
      let(:expected_job_name) { 'rspec-all frontend_fixture 1/7' }

      it_behaves_like 'merge request pipeline'
    end

    # code-patterns, code-backstage-patterns, backend patterns, code-qa-patterns
    context 'when MR labeled with `pipeline:expedite pipeline::expedited` is changing keeps/quarantine-test.rb' do
      let(:labels_string) { 'pipeline:expedite pipeline::expedited' }
      let(:changed_files) { ['keeps/quarantine-test.rb'] }
      let(:expected_job_name) { 'rails-production-server-boot-puma-cng' }

      it_behaves_like 'merge request pipeline'
    end

    # Reminder, we are NOT verifying the CI config from the remote stable branch
    # This test just mocks the target branch name to be a stable branch
    # the tested config is what's currently in the local .gitlab/ci folders

    # Test: remove the following rules from `.frontend:rules:default-frontend-jobs`:
    #   - <<: *if-default-refs
    #     changes: *code-backstage-patterns
    context 'when MR targeting a stable branch is changing keeps/' do
      let(:target_branch)           { '16-10-stable-ee' }
      let(:create_pipeline_service) { Ci::CreatePipelineService.new(project, user, ref: target_branch) }
      let(:labels_string)           { '' }
      let(:changed_files)           { ['keeps/quarantine-test.rb'] }
      let(:expected_job_name)       { 'rspec-all frontend_fixture 1/7' }

      before do
        sync_local_files_to_project(
          project,
          user,
          target_branch,
          files: ci_glob
        )
      end

      it_behaves_like 'merge request pipeline'
    end
  end
end
