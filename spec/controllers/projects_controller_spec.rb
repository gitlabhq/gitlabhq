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

    context "rendering default project view" do
      render_views

      it "shold render the activity view", focus: true do
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive(:project_view).and_return('activity')
        get :show, namespace_id: public_project.namespace.path, id: public_project.path
        expect(response).to render_template('_activity')
      end

      it "shold render the readme view", focus: true do
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive(:project_view).and_return('readme')
        get :show, namespace_id: public_project.namespace.path, id: public_project.path
        expect(response).to render_template('_readme')
      end

      it "shold render the files view", focus: true do
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive(:project_view).and_return('files')
        get :show, namespace_id: public_project.namespace.path, id: public_project.path
        expect(response).to render_template('_files')
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
