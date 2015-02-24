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

    before {
      post :create,
        namespace_id: project.namespace.to_param,
        project_id: project.to_param,
        branch_name: branch,
        ref: ref
    }

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
  end
end
