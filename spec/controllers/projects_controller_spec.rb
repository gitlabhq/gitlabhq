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

      it "renders the activity view" do
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive(:project_view).and_return('activity')

        get :show, namespace_id: public_project.namespace.path, id: public_project.path
        expect(response).to render_template('_activity')
      end

      it "renders the readme view" do
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive(:project_view).and_return('readme')

        get :show, namespace_id: public_project.namespace.path, id: public_project.path
        expect(response).to render_template('_readme')
      end

      it "renders the files view" do
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive(:project_view).and_return('files')

        get :show, namespace_id: public_project.namespace.path, id: public_project.path
        expect(response).to render_template('_files')
      end
    end

    context "when requested with case sensitive namespace and project path" do
      context "when there is a match with the same casing" do
        it "loads the project" do
          get :show, namespace_id: public_project.namespace.path, id: public_project.path

          expect(assigns(:project)).to eq(public_project)
          expect(response.status).to eq(200)
        end
      end

      context "when there is a match with different casing" do
        it "redirects to the normalized path" do
          get :show, namespace_id: public_project.namespace.path, id: public_project.path.upcase

          expect(assigns(:project)).to eq(public_project)
          expect(response).to redirect_to("/#{public_project.path_with_namespace}")
        end


        # MySQL queries are case insensitive by default, so this spec would fail.
        if Gitlab::Database.postgresql?
          context "when there is also a match with the same casing" do

            let!(:other_project) { create(:project, :public, namespace: public_project.namespace, path: public_project.path.upcase) }

            it "loads the exactly matched project" do

              get :show, namespace_id: public_project.namespace.path, id: public_project.path.upcase

              expect(assigns(:project)).to eq(other_project)
              expect(response.status).to eq(200)
            end
          end
        end
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

  describe "DELETE remove_fork" do
    context 'when signed in' do
      before do
        sign_in(user)
      end

      context 'with forked project' do
        let(:project_fork) { create(:project, namespace: user.namespace) }

        before do
          create(:forked_project_link, forked_to_project: project_fork)
        end

        it 'should remove fork from project' do
          delete(:remove_fork,
              namespace_id: project_fork.namespace.to_param,
              id: project_fork.to_param, format: :js)

          expect(project_fork.forked?).to be_falsey
          expect(flash[:notice]).to eq('The fork relationship has been removed.')
          expect(response).to render_template(:remove_fork)
        end
      end

      context 'when project not forked' do
        let(:unforked_project) { create(:project, namespace: user.namespace) }

        it 'should do nothing if project was not forked' do
          delete(:remove_fork,
              namespace_id: unforked_project.namespace.to_param,
              id: unforked_project.to_param, format: :js)

          expect(flash[:notice]).to be_nil
          expect(response).to render_template(:remove_fork)
        end
      end
    end

    it "does nothing if user is not signed in" do
      delete(:remove_fork,
          namespace_id: project.namespace.to_param,
          id: project.to_param, format: :js)
      expect(response.status).to eq(401)
    end
  end
end
