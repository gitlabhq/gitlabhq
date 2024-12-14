# frozen_string_literal: true

RSpec.shared_context 'with simulated pipeline attributes and shared project and user' do
  let(:ci_server_host) { 'gitlab.com' }
  let(:ci_project_namespace) { pipeline_project.namespace.path }
  let(:ci_project_path) { "#{ci_project_namespace}/#{ci_project_name}" }
  let(:ci_project_name) { pipeline_project.path }
  let(:ci_pipeline_source) { 'push' }

  let(:variables_attributes_base) do
    [
      { key: 'CI_SERVER_HOST', value: ci_server_host },
      { key: 'CI_PROJECT_NAMESPACE', value: ci_project_namespace },
      { key: 'CI_PROJECT_PATH', value: ci_project_path },
      { key: 'CI_PROJECT_NAME', value: ci_project_name },
      { key: 'CI_PIPELINE_SOURCE', value: ci_pipeline_source },
      { key: 'GITLAB_INTERNAL', value: 'true' }
    ]
  end

  let(:jobs) { pipeline.stages.flat_map { |s| s.statuses.map(&:name) } }

  let_it_be(:group) { create(:group, path: 'gitlab-org') }
  let_it_be(:gitlab_org_gitlab_project) { create(:project, :empty_repo, group: group, path: 'gitlab') }
  let_it_be(:user) { create(:user) }
  let_it_be(:ci_glob) { Dir.glob("{.gitlab-ci.yml,.gitlab/**/*.yml}").freeze }
  let_it_be(:ci_glob_with_common_file_globs) { [*ci_glob, 'lib/api/lint.rb', 'doc/index.md'] }
  let_it_be(:master_branch) { 'master' }

  around do |example|
    with_net_connect_allowed { example.run } # creating pipeline requires network call to fetch templates
  end

  before_all do
    gitlab_org_gitlab_project.add_developer(user)

    sync_local_files_to_project(
      gitlab_org_gitlab_project,
      user,
      master_branch,
      files: ci_glob_with_common_file_globs
    )
  end

  before do
    pipeline_project.update!(ci_pipeline_variables_minimum_override_role: :developer)
    # delete once we have a migration to permanently increase limit
    stub_application_setting(max_yaml_size_bytes: 2.megabytes)
  end
end

RSpec.shared_context 'with simulated MR pipeline attributes' do
  let(:ci_pipeline_source) { 'merge_request_event' }
  let(:ci_merge_request_event_type) { 'merged_result' }
  let(:mr_labels) { [] }

  let(:mr_pipeline_variables_attributes) do
    [
      *variables_attributes_base,
      { key: 'CI_COMMIT_REF_NAME', value: source_branch },
      { key: 'CI_MERGE_REQUEST_EVENT_TYPE', value: ci_merge_request_event_type }
    ]
  end

  let(:create_pipeline_service) { Ci::CreatePipelineService.new(target_project, user, ref: target_branch) }

  let(:source_project) { gitlab_org_gitlab_project }
  let(:target_project) { gitlab_org_gitlab_project }
  let(:source_branch) { "feature_branch_ci_#{SecureRandom.uuid}" }
  let(:target_branch) { master_branch }

  let(:merge_request) do
    create(:labeled_merge_request,
      source_project: source_project,
      source_branch: source_branch,
      target_project: target_project,
      target_branch: target_branch,
      labels: mr_labels.map { |label_title| create(:label, title: label_title) }
    )
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
end

RSpec.shared_examples 'default branch pipeline' do
  it 'is valid' do
    expect(pipeline.yaml_errors).to be nil
    expect(pipeline.errors).to be_empty
    expect(pipeline.status).to eq('created')
    expect(jobs).to include(expected_job_name)
  end
end

RSpec.shared_examples 'merge request pipeline' do
  it "succeeds with expected job" do
    expect(pipeline.yaml_errors).to be nil
    expect(pipeline.errors).to be_empty
    expect(pipeline.status).to eq('created')
    expect(jobs).to include(expected_job_name)
  end
end

RSpec.shared_examples 'merge train pipeline' do
  let(:ci_merge_request_event_type) { 'merge_train' }

  it "succeeds with expected job" do
    expect(pipeline.yaml_errors).to be nil
    expect(pipeline.errors).to be_empty
    expect(pipeline.status).to eq('created')
    expect(jobs).to include('pre-merge-checks')
    expect(jobs).not_to include('upload-frontend-fixtures')
  end
end

module CiConfigurationValidationHelper
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
end
