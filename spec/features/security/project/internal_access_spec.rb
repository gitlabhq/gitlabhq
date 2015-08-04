require 'spec_helper'

describe "Internal Project Access", feature: true  do
  include AccessMatchers

  let(:project) { create(:project, :internal) }

  let(:master) { create(:user) }
  let(:guest) { create(:user) }
  let(:reporter) { create(:user) }

  before do
    # full access
    project.team << [master, :master]

    # readonly
    project.team << [reporter, :reporter]
  end

  describe "Project should be internal" do
    subject { project }

    describe '#internal?' do
      subject { super().internal? }
      it { is_expected.to be_truthy }
    end
  end

  describe "GET /:project_path" do
    subject { namespace_project_path(project.namespace, project) }

    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for guest }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/tree/master" do
    subject { namespace_project_tree_path(project.namespace, project, project.repository.root_ref) }

    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for guest }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/commits/master" do
    subject { namespace_project_commits_path(project.namespace, project, project.repository.root_ref, limit: 1) }

    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for guest }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/commit/:sha" do
    subject { namespace_project_commit_path(project.namespace, project, project.repository.commit) }

    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for guest }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/compare" do
    subject { namespace_project_compare_index_path(project.namespace, project) }

    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for guest }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/project_members" do
    subject { namespace_project_project_members_path(project.namespace, project) }

    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_denied_for reporter }
    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_denied_for guest }
    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/blob" do
    before do
      commit = project.repository.commit
      path = '.gitignore'
      @blob_path = namespace_project_blob_path(project.namespace, project, File.join(commit.id, path))
    end

    it { expect(@blob_path).to be_allowed_for master }
    it { expect(@blob_path).to be_allowed_for reporter }
    it { expect(@blob_path).to be_allowed_for :admin }
    it { expect(@blob_path).to be_allowed_for guest }
    it { expect(@blob_path).to be_allowed_for :user }
    it { expect(@blob_path).to be_denied_for :visitor }
  end

  describe "GET /:project_path/edit" do
    subject { edit_namespace_project_path(project.namespace, project) }

    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_denied_for reporter }
    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_denied_for guest }
    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/deploy_keys" do
    subject { namespace_project_deploy_keys_path(project.namespace, project) }

    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_denied_for reporter }
    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_denied_for guest }
    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/issues" do
    subject { namespace_project_issues_path(project.namespace, project) }

    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for guest }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/issues/:id/edit" do
    let(:issue) { create(:issue, project: project) }
    subject { edit_namespace_project_issue_path(project.namespace, project, issue) }

    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_denied_for guest }
    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/snippets" do
    subject { namespace_project_snippets_path(project.namespace, project) }

    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for guest }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/snippets/new" do
    subject { new_namespace_project_snippet_path(project.namespace, project) }

    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_denied_for guest }
    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/merge_requests" do
    subject { namespace_project_merge_requests_path(project.namespace, project) }

    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for guest }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/merge_requests/new" do
    subject { new_namespace_project_merge_request_path(project.namespace, project) }

    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_denied_for reporter }
    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_denied_for guest }
    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/branches" do
    subject { namespace_project_branches_path(project.namespace, project) }

    before do
      # Speed increase
      allow_any_instance_of(Project).to receive(:branches).and_return([])
    end

    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for guest }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/tags" do
    subject { namespace_project_tags_path(project.namespace, project) }

    before do
      # Speed increase
      allow_any_instance_of(Project).to receive(:tags).and_return([])
    end

    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for guest }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/hooks" do
    subject { namespace_project_hooks_path(project.namespace, project) }

    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_denied_for reporter }
    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_denied_for guest }
    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :visitor }
  end
end
