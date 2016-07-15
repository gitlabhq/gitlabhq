require 'spec_helper'

describe Projects::BranchesController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)

    project.team << [user, :master]

    allow(project).to receive(:branches).and_return(['master', 'foo/bar/baz'])
    allow(project).to receive(:tags).and_return(['v1.0.0', 'v2.0.0'])
    controller.instance_variable_set(:@project, project)
  end

  describe "POST create" do
    render_views

    context "on creation of a new branch" do
      before do
        post :create,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          branch_name: branch,
          ref: ref
      end

      context "valid branch name, valid source" do
        let(:branch) { "merge_branch" }
        let(:ref) { "master" }
        it 'redirects' do
          expect(subject).
            to redirect_to("/#{project.path_with_namespace}/tree/merge_branch")
        end
      end

      context "invalid branch name, valid ref" do
        let(:branch) { "<script>alert('merge');</script>" }
        let(:ref) { "master" }
        it 'redirects' do
          expect(subject).
            to redirect_to("/#{project.path_with_namespace}/tree/alert('merge');")
        end
      end

      context "valid branch name, invalid ref" do
        let(:branch) { "merge_branch" }
        let(:ref) { "<script>alert('ref');</script>" }
        it { is_expected.to render_template('new') }
      end

      context "invalid branch name, invalid ref" do
        let(:branch) { "<script>alert('merge');</script>" }
        let(:ref) { "<script>alert('ref');</script>" }
        it { is_expected.to render_template('new') }
      end

      context "valid branch name with encoded slashes" do
        let(:branch) { "feature%2Ftest" }
        let(:ref) { "<script>alert('ref');</script>" }
        it { is_expected.to render_template('new') }
        it { project.repository.branch_names.include?('feature/test') }
      end
    end

    describe "created from the new branch button on issues" do
      let(:branch) { "1-feature-branch" }
      let!(:issue) { create(:issue, project: project) }

      it 'redirects' do
        post :create,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          branch_name: branch,
          issue_iid: issue.iid

        expect(subject).
          to redirect_to("/#{project.path_with_namespace}/tree/1-feature-branch")
      end

      it 'posts a system note' do
        expect(SystemNoteService).to receive(:new_issue_branch).with(issue, project, user, "1-feature-branch")

        post :create,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          branch_name: branch,
          issue_iid: issue.iid
      end
    end
  end

  describe "POST destroy with HTML format" do
    render_views

    it 'returns 303' do
      post :destroy,
           format: :html,
           id: 'foo/bar/baz',
           namespace_id: project.namespace.to_param,
           project_id: project.to_param

      expect(response).to have_http_status(303)
    end
  end

  describe "POST destroy" do
    render_views

    before do
      post :destroy,
           format: :js,
           id: branch,
           namespace_id: project.namespace.to_param,
           project_id: project.to_param
    end

    context "valid branch name, valid source" do
      let(:branch) { "feature" }

      it { expect(response).to have_http_status(200) }
    end

    context "valid branch name with unencoded slashes" do
      let(:branch) { "improve/awesome" }

      it { expect(response).to have_http_status(200) }
    end

    context "valid branch name with encoded slashes" do
      let(:branch) { "improve%2Fawesome" }

      it { expect(response).to have_http_status(200) }
    end
    context "invalid branch name, valid ref" do
      let(:branch) { "no-branch" }

      it { expect(response).to have_http_status(404) }
    end
  end
end
