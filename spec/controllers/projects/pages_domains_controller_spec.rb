# frozen_string_literal: true

require 'spec_helper'

describe Projects::PagesDomainsController do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let!(:pages_domain) { create(:pages_domain, project: project) }

  let(:request_params) do
    {
      namespace_id: project.namespace,
      project_id: project
    }
  end

  let(:pages_domain_params) do
    attributes_for(:pages_domain, domain: 'my.otherdomain.com').slice(:key, :certificate, :domain).tap do |params|
      params[:user_provided_key] = params.delete(:key)
      params[:user_provided_certificate] = params.delete(:certificate)
    end
  end

  before do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
    sign_in(user)
    project.add_maintainer(user)
  end

  describe 'GET show' do
    def make_request
      get(:show, params: request_params.merge(id: pages_domain.domain))
    end

    it "redirects to the 'edit' page" do
      make_request

      expect(response).to redirect_to(edit_project_pages_domain_path(project, pages_domain.domain))
    end

    context 'when user is developer' do
      before do
        project.add_developer(user)
      end

      it 'renders 404 page' do
        make_request

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET new' do
    it "displays the 'new' page" do
      get(:new, params: request_params)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to render_template('new')
    end
  end

  describe 'POST create' do
    it "creates a new pages domain" do
      expect do
        post(:create, params: request_params.merge(pages_domain: pages_domain_params))
      end.to change { PagesDomain.count }.by(1)

      created_domain = PagesDomain.reorder(:id).last

      expect(created_domain).to be_present
      expect(response).to redirect_to(edit_project_pages_domain_path(project, created_domain))
    end
  end

  describe 'GET edit' do
    it "displays the 'edit' page" do
      get(:edit, params: request_params.merge(id: pages_domain.domain))

      expect(response).to have_gitlab_http_status(200)
      expect(response).to render_template('edit')
    end
  end

  describe 'PATCH update' do
    before do
      controller.instance_variable_set(:@domain, pages_domain)
    end

    let(:params) do
      request_params.merge(id: pages_domain.domain, pages_domain: pages_domain_params)
    end

    context 'with valid params' do
      let(:pages_domain_params) do
        attributes_for(:pages_domain, :with_trusted_chain).slice(:key, :certificate).tap do |params|
          params[:user_provided_key] = params.delete(:key)
          params[:user_provided_certificate] = params.delete(:certificate)
        end
      end

      it 'updates the domain' do
        expect do
          patch(:update, params: params)
        end.to change { pages_domain.reload.certificate }.to(pages_domain_params[:user_provided_certificate])
      end

      it 'redirects to the project page' do
        patch(:update, params: params)

        expect(flash[:notice]).to eq 'Domain was updated'
        expect(response).to redirect_to(project_pages_path(project))
      end
    end

    context 'with key parameter' do
      before do
        pages_domain.update!(key: nil, certificate: nil, certificate_source: 'gitlab_provided')
      end

      it 'marks certificate as provided by user' do
        expect do
          patch(:update, params: params)
        end.to change { pages_domain.reload.certificate_source }.from('gitlab_provided').to('user_provided')
      end
    end

    context 'the domain is invalid' do
      let(:pages_domain_params) { { user_provided_certificate: 'blabla' } }

      it 'renders the edit action' do
        patch(:update, params: params)

        expect(response).to render_template('edit')
      end
    end

    context 'when parameters include the domain' do
      it 'does not update domain' do
        expect do
          patch(:update, params: params.deep_merge(pages_domain: { domain: 'abc' }))
        end.not_to change { pages_domain.reload.domain }
      end
    end
  end

  describe 'POST verify' do
    let(:params) { request_params.merge(id: pages_domain.domain) }

    def stub_service
      service = double(:service)

      expect(VerifyPagesDomainService).to receive(:new) { service }

      service
    end

    it 'handles verification success' do
      expect(stub_service).to receive(:execute).and_return(status: :success)

      post :verify, params: params

      expect(response).to redirect_to edit_project_pages_domain_path(project, pages_domain)
      expect(flash[:notice]).to eq('Successfully verified domain ownership')
    end

    it 'handles verification failure' do
      expect(stub_service).to receive(:execute).and_return(status: :failed)

      post :verify, params: params

      expect(response).to redirect_to edit_project_pages_domain_path(project, pages_domain)
      expect(flash[:alert]).to eq('Failed to verify domain ownership')
    end

    it 'returns a 404 response for an unknown domain' do
      post :verify, params: request_params.merge(id: 'unknown-domain')

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'DELETE destroy' do
    it "deletes the pages domain" do
      expect do
        delete(:destroy, params: request_params.merge(id: pages_domain.domain))
      end.to change { PagesDomain.count }.by(-1)

      expect(response).to redirect_to(project_pages_path(project))
    end
  end

  describe 'DELETE #clean_certificate' do
    subject do
      delete(:clean_certificate, params: request_params.merge(id: pages_domain.domain))
    end

    it 'redirects to edit page' do
      subject

      expect(response).to redirect_to(edit_project_pages_domain_path(project, pages_domain))
    end

    it 'removes certificate' do
      expect do
        subject
      end.to change { pages_domain.reload.certificate }.to(nil)
        .and change { pages_domain.reload.key }.to(nil)
    end

    it 'sets certificate source to user_provided' do
      pages_domain.update!(certificate_source: :gitlab_provided)

      expect do
        subject
      end.to change { pages_domain.reload.certificate_source }.from("gitlab_provided").to("user_provided")
    end

    context 'when pages_https_only is set' do
      before do
        project.update!(pages_https_only: true)
        stub_pages_setting(external_https: '127.0.0.1')
      end

      it 'does not remove certificate' do
        subject

        pages_domain.reload
        expect(pages_domain.certificate).to be_present
        expect(pages_domain.key).to be_present
      end

      it 'redirects to edit page with a flash message' do
        subject

        expect(flash[:alert]).to include('Certificate')
        expect(flash[:alert]).to include('Key')
        expect(response).to redirect_to(edit_project_pages_domain_path(project, pages_domain))
      end
    end
  end

  context 'pages disabled' do
    before do
      allow(Gitlab.config.pages).to receive(:enabled).and_return(false)
    end

    describe 'GET show' do
      it 'returns 404 status' do
        get(:show, params: request_params.merge(id: pages_domain.domain))

        expect(response).to have_gitlab_http_status(404)
      end
    end

    describe 'GET new' do
      it 'returns 404 status' do
        get :new, params: request_params

        expect(response).to have_gitlab_http_status(404)
      end
    end

    describe 'POST create' do
      it "returns 404 status" do
        post(:create, params: request_params.merge(pages_domain: pages_domain_params))

        expect(response).to have_gitlab_http_status(404)
      end
    end

    describe 'DELETE destroy' do
      it "deletes the pages domain" do
        delete(:destroy, params: request_params.merge(id: pages_domain.domain))

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
