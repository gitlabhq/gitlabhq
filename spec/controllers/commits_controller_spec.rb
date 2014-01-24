require 'spec_helper'

describe Projects::CommitsController do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    sign_in(user)

    project.team << [user, :master]
  end

  describe "GET show" do
    context "as atom feed" do
      it "should render as atom" do
        get :show, project_id: project.to_param, id: "master", format: "atom"
        response.should be_success
        response.content_type.should == 'application/atom+xml'
      end
    end
  end
end
