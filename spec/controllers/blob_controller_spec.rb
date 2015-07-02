require 'spec_helper'

describe Projects::BlobController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)

    project.team << [user, :master]

    allow(project).to receive(:branches).and_return(['master', 'foo/bar/baz'])
    allow(project).to receive(:tags).and_return(['v1.0.0', 'v2.0.0'])
    controller.instance_variable_set(:@project, project)
  end

  describe "GET show" do
    render_views

    before do
      get(:show,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          id: id)
    end

    context "valid branch, valid file" do
      let(:id) { 'master/README.md' }
      it { is_expected.to respond_with(:success) }
    end

    context "valid branch, invalid file" do
      let(:id) { 'master/invalid-path.rb' }
      it { is_expected.to respond_with(:not_found) }
    end

    context "invalid branch, valid file" do
      let(:id) { 'invalid-branch/README.md' }
      it { is_expected.to respond_with(:not_found) }
    end
  end

  describe 'GET show with tree path' do
    render_views

    before do
      get(:show,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          id: id)
      controller.instance_variable_set(:@blob, nil)
    end

    context 'redirect to tree' do
      let(:id) { 'markdown/doc' }
      it 'redirects' do
        expect(subject).
          to redirect_to("/#{project.path_with_namespace}/tree/markdown/doc")
      end
    end
  end
end
