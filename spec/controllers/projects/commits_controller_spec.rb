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
        get(:show,
            namespace_id: project.namespace.to_param,
            project_id: project.to_param,
            id: "master",
            format: "atom")
        expect(response).to be_success
        expect(response.content_type).to eq('application/atom+xml')
      end
    end
  end
end
