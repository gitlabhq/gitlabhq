require 'spec_helper'

describe ProjectsController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:note) { create(:note, :project_id => project.code) }

  before do
    sign_in(user)
    project.add_access(user, :read, :admin)
  end
  
  describe "GET files" do
    # Make sure any errors accessing the tree in our views bubble up to this spec
    render_views

    before { 
      get :files, id: project.code
    }

    context "utf-8 filename attachment" do
      it { should respond_with(:success) }
    end
  end
end