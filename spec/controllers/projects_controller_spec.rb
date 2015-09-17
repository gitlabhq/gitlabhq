require('spec_helper')

describe ProjectsController do
  let(:project) { create(:project) }
  let(:public_project) { create(:project, :public) }
  let(:user)    { create(:user) }
  let(:jpg)     { fixture_file_upload(Rails.root + 'spec/fixtures/rails_sample.jpg', 'image/jpg') }
  let(:txt)     { fixture_file_upload(Rails.root + 'spec/fixtures/doc_sample.txt', 'text/plain') }

  describe "GET show" do

    context "when requested by `go get`" do
      render_views

      it "renders the go-import meta tag" do
        get :show, "go-get" => "1", namespace_id: "bogus_namespace", id: "bogus_project"

        expect(response.body).to include("name='go-import'")

        content = "localhost/bogus_namespace/bogus_project git http://localhost/bogus_namespace/bogus_project.git"
        expect(response.body).to include("content='#{content}'")
      end
    end

    context "when requested with case sensitive namespace and project path" do
      it "redirects to the normalized path for case mismatch" do
        get :show, namespace_id: public_project.namespace.path, id: public_project.path.upcase

        expect(response).to redirect_to("/#{public_project.path_with_namespace}")
      end

      it "loads the page if normalized path matches request path" do
        get :show, namespace_id: public_project.namespace.path, id: public_project.path

        expect(response.status).to eq(200)
      end
    end
  end

  describe "POST #toggle_star" do
    it "toggles star if user is signed in" do
      sign_in(user)
      expect(user.starred?(public_project)).to be_falsey
      post(:toggle_star,
           namespace_id: public_project.namespace.to_param,
           id: public_project.to_param)
      expect(user.starred?(public_project)).to be_truthy
      post(:toggle_star,
           namespace_id: public_project.namespace.to_param,
           id: public_project.to_param)
      expect(user.starred?(public_project)).to be_falsey
    end

    it "does nothing if user is not signed in" do
      post(:toggle_star,
           namespace_id: project.namespace.to_param,
           id: public_project.to_param)
      expect(user.starred?(public_project)).to be_falsey
      post(:toggle_star,
           namespace_id: project.namespace.to_param,
           id: public_project.to_param)
      expect(user.starred?(public_project)).to be_falsey
    end
  end
end
