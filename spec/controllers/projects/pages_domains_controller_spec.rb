require 'spec_helper'

describe Projects::PagesDomainsController do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let!(:pages_domain) { create(:pages_domain, project: project) }

  let(:request_params) do
    {
      namespace_id: project.namespace,
      project_id: project
    }
  end

  let(:pages_domain_params) do
    build(:pages_domain, :with_certificate, :with_key, domain: 'my.otherdomain.com').slice(:key, :certificate, :domain)
  end

  before do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
    sign_in(user)
    project.add_master(user)
  end

  describe 'GET show' do
    it "displays the 'show' page" do
      get(:show, request_params.merge(id: pages_domain.domain))

      expect(response).to have_http_status(200)
      expect(response).to render_template('show')
    end
  end

  describe 'GET new' do
    it "displays the 'new' page" do
      get(:new, request_params)

      expect(response).to have_http_status(200)
      expect(response).to render_template('new')
    end
  end

  describe 'POST create' do
    it "creates a new pages domain" do
      expect do
        post(:create, request_params.merge(pages_domain: pages_domain_params))
      end.to change { PagesDomain.count }.by(1)

      expect(response).to redirect_to(project_pages_path(project))
    end
  end

  describe 'DELETE destroy' do
    it "deletes the pages domain" do
      expect do
        delete(:destroy, request_params.merge(id: pages_domain.domain))
      end.to change { PagesDomain.count }.by(-1)

      expect(response).to redirect_to(project_pages_path(project))
    end
  end

  context 'pages disabled' do
    before do
      allow(Gitlab.config.pages).to receive(:enabled).and_return(false)
    end

    describe 'GET show' do
      it 'returns 404 status' do
        get(:show, request_params.merge(id: pages_domain.domain))

        expect(response).to have_http_status(404)
      end
    end

    describe 'GET new' do
      it 'returns 404 status' do
        get :new, request_params

        expect(response).to have_http_status(404)
      end
    end

    describe 'POST create' do
      it "returns 404 status" do
        post(:create, request_params.merge(pages_domain: pages_domain_params))

        expect(response).to have_http_status(404)
      end
    end

    describe 'DELETE destroy' do
      it "deletes the pages domain" do
        delete(:destroy, request_params.merge(id: pages_domain.domain))

        expect(response).to have_http_status(404)
      end
    end
  end
end
