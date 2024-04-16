# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Internal Project Access", feature_category: :system_access do
  include AccessMatchers

  let_it_be(:project, reload: true) { create(:project, :internal, :repository, :with_namespace_settings) }

  describe "Project should be internal" do
    describe '#internal?' do
      subject { project.internal? }

      it { is_expected.to be_truthy }
    end
  end

  describe "GET /:project_path" do
    subject { project_path(project) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/-/tree/master" do
    subject { project_tree_path(project, project.repository.root_ref) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/-/commits/master" do
    subject { project_commits_path(project, project.repository.root_ref, limit: 1) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/-/commit/:sha" do
    subject { project_commit_path(project, project.repository.commit) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/-/compare" do
    subject { project_compare_index_path(project) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/-/project_members" do
    subject { project_project_members_path(project) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:visitor) }
    it { is_expected.to be_denied_for(:external) }
  end

  describe "GET /:project_path/-/settings/ci_cd" do
    subject { project_settings_ci_cd_path(project) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is denied for admin when admin mode is disabled') { is_expected.to be_denied_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_denied_for(:developer).of(project) }
    it { is_expected.to be_denied_for(:reporter).of(project) }
    it { is_expected.to be_denied_for(:guest).of(project) }
    it { is_expected.to be_denied_for(:user) }
    it { is_expected.to be_denied_for(:visitor) }
    it { is_expected.to be_denied_for(:external) }
  end

  describe "GET /:project_path/-/settings/repository" do
    subject { project_settings_repository_path(project) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is denied for admin when admin mode is disabled') { is_expected.to be_denied_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_denied_for(:developer).of(project) }
    it { is_expected.to be_denied_for(:reporter).of(project) }
    it { is_expected.to be_denied_for(:guest).of(project) }
    it { is_expected.to be_denied_for(:user) }
    it { is_expected.to be_denied_for(:visitor) }
    it { is_expected.to be_denied_for(:external) }
  end

  describe "GET /:project_path/-/blob" do
    let(:commit) { project.repository.commit }

    subject { project_blob_path(project, File.join(commit.id, '.gitignore')) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/edit" do
    subject { edit_project_path(project) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is denied for admin when admin mode is disabled') { is_expected.to be_denied_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_denied_for(:developer).of(project) }
    it { is_expected.to be_denied_for(:reporter).of(project) }
    it { is_expected.to be_denied_for(:guest).of(project) }
    it { is_expected.to be_denied_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/deploy_keys" do
    subject { project_deploy_keys_path(project) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is denied for admin when admin mode is disabled') { is_expected.to be_denied_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_denied_for(:developer).of(project) }
    it { is_expected.to be_denied_for(:reporter).of(project) }
    it { is_expected.to be_denied_for(:guest).of(project) }
    it { is_expected.to be_denied_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/issues" do
    subject { project_issues_path(project) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/issues/:id/edit" do
    let(:issue) { create(:issue, project: project) }

    subject { edit_project_issue_path(project, issue) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is denied for admin when admin mode is disabled') { is_expected.to be_denied_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_denied_for(:guest).of(project) }
    it { is_expected.to be_denied_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/snippets" do
    subject { project_snippets_path(project) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/snippets/new" do
    subject { new_project_snippet_path(project) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is denied for admin when admin mode is disabled') { is_expected.to be_denied_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_denied_for(:guest).of(project) }
    it { is_expected.to be_denied_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/-/merge_requests" do
    subject { project_merge_requests_path(project) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/-/merge_requests/new" do
    subject { project_new_merge_request_path(project) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is denied for admin when admin mode is disabled') { is_expected.to be_denied_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_denied_for(:reporter).of(project) }
    it { is_expected.to be_denied_for(:guest).of(project) }
    it { is_expected.to be_denied_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/-/branches" do
    subject { project_branches_path(project) }

    before do
      # Speed increase
      allow_next_instance_of(Project) do |instance|
        allow(instance).to receive(:branches).and_return([])
      end
    end

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/-/tags" do
    subject { project_tags_path(project) }

    before do
      # Speed increase
      allow_next_instance_of(Project) do |instance|
        allow(instance).to receive(:tags).and_return([])
      end
    end

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/-/settings/integrations" do
    subject { project_settings_integrations_path(project) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is denied for admin when admin mode is disabled') { is_expected.to be_denied_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_denied_for(:developer).of(project) }
    it { is_expected.to be_denied_for(:reporter).of(project) }
    it { is_expected.to be_denied_for(:guest).of(project) }
    it { is_expected.to be_denied_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/pipelines" do
    subject { project_pipelines_path(project) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/pipelines/:id" do
    let(:pipeline) { create(:ci_pipeline, project: project) }

    subject { project_pipeline_path(project, pipeline) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/builds" do
    subject { project_jobs_path(project) }

    context "when allowed for public and internal" do
      before do
        project.update!(public_builds: true)
      end

      it { is_expected.to be_allowed_for(:admin) }
      it { is_expected.to be_allowed_for(:owner).of(project) }
      it { is_expected.to be_allowed_for(:maintainer).of(project) }
      it { is_expected.to be_allowed_for(:developer).of(project) }
      it { is_expected.to be_allowed_for(:reporter).of(project) }
      it { is_expected.to be_allowed_for(:guest).of(project) }
      it { is_expected.to be_allowed_for(:user) }
      it { is_expected.to be_denied_for(:external) }
      it { is_expected.to be_denied_for(:visitor) }
    end

    context "when disallowed for public and internal" do
      before do
        project.update!(public_builds: false)
      end

      it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
      it('is denied for admin when admin mode is disabled') { is_expected.to be_denied_for(:admin) }
      it { is_expected.to be_allowed_for(:owner).of(project) }
      it { is_expected.to be_allowed_for(:maintainer).of(project) }
      it { is_expected.to be_allowed_for(:developer).of(project) }
      it { is_expected.to be_allowed_for(:reporter).of(project) }
      it { is_expected.to be_denied_for(:guest).of(project) }
      it { is_expected.to be_denied_for(:user) }
      it { is_expected.to be_denied_for(:external) }
      it { is_expected.to be_denied_for(:visitor) }
    end
  end

  describe "GET /:project_path/builds/:id" do
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:build) { create(:ci_build, pipeline: pipeline) }

    subject { project_job_path(project, build.id) }

    context "when allowed for public and internal" do
      before do
        project.update!(public_builds: true)
      end

      it { is_expected.to be_allowed_for(:admin) }
      it { is_expected.to be_allowed_for(:owner).of(project) }
      it { is_expected.to be_allowed_for(:maintainer).of(project) }
      it { is_expected.to be_allowed_for(:developer).of(project) }
      it { is_expected.to be_allowed_for(:reporter).of(project) }
      it { is_expected.to be_allowed_for(:guest).of(project) }
      it { is_expected.to be_allowed_for(:user) }
      it { is_expected.to be_denied_for(:external) }
      it { is_expected.to be_denied_for(:visitor) }
    end

    context "when disallowed for public and internal" do
      before do
        project.update!(public_builds: false)
      end

      it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
      it('is denied for admin when admin mode is disabled') { is_expected.to be_denied_for(:admin) }
      it { is_expected.to be_allowed_for(:owner).of(project) }
      it { is_expected.to be_allowed_for(:maintainer).of(project) }
      it { is_expected.to be_allowed_for(:developer).of(project) }
      it { is_expected.to be_allowed_for(:reporter).of(project) }
      it { is_expected.to be_denied_for(:guest).of(project) }
      it { is_expected.to be_denied_for(:user) }
      it { is_expected.to be_denied_for(:external) }
      it { is_expected.to be_denied_for(:visitor) }
    end
  end

  describe 'GET /:project_path/builds/:id/trace' do
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:build) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

    subject { trace_project_job_path(project, build.id) }

    context 'when allowed for public and internal' do
      before do
        project.update!(public_builds: true)
      end

      it { is_expected.to be_allowed_for(:admin) }
      it { is_expected.to be_allowed_for(:owner).of(project) }
      it { is_expected.to be_allowed_for(:maintainer).of(project) }
      it { is_expected.to be_allowed_for(:developer).of(project) }
      it { is_expected.to be_allowed_for(:reporter).of(project) }
      it { is_expected.to be_allowed_for(:guest).of(project) }
      it { is_expected.to be_allowed_for(:user) }
      it { is_expected.to be_denied_for(:external) }
      it { is_expected.to be_denied_for(:visitor) }
    end

    context 'when disallowed for public and internal' do
      before do
        project.update!(public_builds: false)
      end

      it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
      it('is denied for admin when admin mode is disabled') { is_expected.to be_denied_for(:admin) }
      it { is_expected.to be_allowed_for(:owner).of(project) }
      it { is_expected.to be_allowed_for(:maintainer).of(project) }
      it { is_expected.to be_allowed_for(:developer).of(project) }
      it { is_expected.to be_allowed_for(:reporter).of(project) }
      it { is_expected.to be_denied_for(:guest).of(project) }
      it { is_expected.to be_denied_for(:user) }
      it { is_expected.to be_denied_for(:external) }
      it { is_expected.to be_denied_for(:visitor) }
    end
  end

  describe "GET /:project_path/pipeline_schedules" do
    subject { project_pipeline_schedules_path(project) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is allowed for admin when admin mode is disabled') { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/-/environments" do
    subject { project_environments_path(project) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is allowed for admin when admin mode is disabled') { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/-/environments/:id" do
    let(:environment) { create(:environment, project: project) }

    subject { project_environment_path(project, environment) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is allowed for admin when admin mode is disabled') { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/-/environments/:id/deployments" do
    let(:environment) { create(:environment, project: project) }

    subject { project_environment_deployments_path(project, environment) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is allowed for admin when admin mode is disabled') { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/-/environments/new" do
    subject { new_project_environment_path(project) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is denied for admin when admin mode is disabled') { is_expected.to be_denied_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_denied_for(:reporter).of(project) }
    it { is_expected.to be_denied_for(:guest).of(project) }
    it { is_expected.to be_denied_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/container_registry" do
    let(:container_repository) { create(:container_repository) }

    before do
      stub_container_registry_tags(repository: :any, tags: ['latest'])
      stub_container_registry_config(enabled: true)
      stub_container_registry_info
      project.container_repositories << container_repository
      allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(true)
    end

    subject { project_container_registry_index_path(project) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end
end
