require 'spec_helper'

describe Projects::BlobController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)

    project.team << [user, :master]

    project.stub(:branches).and_return(['master', 'foo/bar/baz'])
    project.stub(:tags).and_return(['v1.0.0', 'v2.0.0'])
    controller.instance_variable_set(:@project, project)
  end

  describe "GET show" do
    render_views

    before { get :show, project_id: project.to_param, id: id }

    context "valid branch, valid file" do
      let(:id) { 'master/README.md' }
      it { should respond_with(:success) }
    end

    context "valid branch, invalid file" do
      let(:id) { 'master/invalid-path.rb' }
      it { should respond_with(:not_found) }
    end

    context "invalid branch, valid file" do
      let(:id) { 'invalid-branch/README.md' }
      it { should respond_with(:not_found) }
    end
  end
end
