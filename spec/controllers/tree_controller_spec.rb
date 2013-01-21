require 'spec_helper'

describe TreeController do
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
    # Make sure any errors accessing the tree in our views bubble up to this spec
    render_views

    before { get :show, project_id: project.code, id: id }

    context "valid branch, no path" do
      let(:id) { 'master' }
      it { should respond_with(:success) }
    end

    context "valid branch, valid path" do
      let(:id) { 'master/README.md' }
      it { should respond_with(:success) }
    end

    context "valid branch, invalid path" do
      let(:id) { 'master/invalid-path.rb' }
      it { should respond_with(:not_found) }
    end

    context "invalid branch, valid path" do
      let(:id) { 'invalid-branch/README.md' }
      it { should respond_with(:not_found) }
    end
  end
end
