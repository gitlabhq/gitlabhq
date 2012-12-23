require 'spec_helper'

describe CommitsController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)

    project.add_access(user, :read, :admin)
  end

  describe "GET show" do
    context "as atom feed" do
      it "should render as atom" do
        get :show, project_id: project.path, id: "master.atom"
        response.should be_success
        response.content_type.should == 'application/atom+xml'
      end
    end
  end
end
