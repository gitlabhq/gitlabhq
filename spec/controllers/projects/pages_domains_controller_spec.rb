# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PagesDomainsController, feature_category: :pages do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let!(:pages_domain) { create(:pages_domain, project: project) }
  let(:domain_presenter) { pages_domain.present(current_user: user) }

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
    before do
      controller.instance_variable_set(:@domain, pages_domain)
      allow(pages_domain).to receive(:present).with(current_user: user).and_return(domain_presenter)
    end

    def make_request
      get(:show, params: request_params.merge(id: pages_domain.domain))
    end

    context 'when domain is verified' do
      before do
        allow(domain_presenter).to receive(:needs_verification?).and_return(false)
      end

      it "displays to the 'show' page without warning" do
        make_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('show')
        expect(flash.now[:warning]).to be_nil
      end
    end

    context 'when domain is unverified' do
      before do
        allow(domain_presenter).to receive(:needs_verification?).and_return(true)
      end

      it "displays to the 'show' page with warning" do
        make_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('show')
        expect(flash.now[:warning])
          .to eq('This domain is not verified. You will need to verify ownership before access is enabled.')
      end
    end

    context 'when user is developer' do
      before do
        project.add_developer(user)
      end

      it 'renders 404 page' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET new' do
    it "displays the 'new' page" do
      get(:new, params: request_params)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template('new')
    end
  end

  describe 'POST create' do
    it "creates a new pages domain" do
      expect { post(:create, params: request_params.merge(pages_domain: pages_domain_params)) }
        .to change { PagesDomain.count }.by(1)
        .and publish_event(::Pages::Domains::PagesDomainCreatedEvent)
          .with(
            project_id: project.id,
            namespace_id: project.namespace.id,
            root_namespace_id: project.root_namespace.id,
            domain_id: kind_of(Numeric),
            domain: pages_domain_params[:domain]
          )

      created_domain = PagesDomain.reorder(:id).last

      expect(created_domain).to be_present
      expect(response).to redirect_to(project_pages_domain_path(project, created_domain))
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

      it 'publishes PagesDomainUpdatedEvent event' do
        expect { patch(:update, params: params) }
          .to publish_event(::Pages::Domains::PagesDomainUpdatedEvent)
          .with(
            project_id: project.id,
            namespace_id: project.namespace.id,
            root_namespace_id: project.root_namespace.id,
            domain_id: pages_domain.id,
            domain: pages_domain.domain
          )
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

      it 'renders the show action' do
        patch(:update, params: params)

        expect(response).to render_template('show')
      end

      it 'does not publish PagesDomainUpdatedEvent event' do
        expect { patch(:update, params: params) }
          .to not_publish_event(::Pages::Domains::PagesDomainUpdatedEvent)
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

    it 'handles verification success' do
      expect_next_instance_of(VerifyPagesDomainService, pages_domain) do |service|
        expect(service).to receive(:execute).and_return(status: :success)
      end

      post :verify, params: params

      expect(response).to redirect_to project_pages_domain_path(project, pages_domain)
      expect(flash[:notice]).to eq('Successfully verified domain ownership')
    end

    it 'handles verification failure' do
      expect_next_instance_of(VerifyPagesDomainService, pages_domain) do |service|
        expect(service).to receive(:execute).and_return(status: :failed)
      end

      post :verify, params: params

      expect(response).to redirect_to project_pages_domain_path(project, pages_domain)
      expect(flash[:alert]).to eq('Failed to verify domain ownership')
    end

    it 'returns a 404 response for an unknown domain' do
      post :verify, params: request_params.merge(id: 'unknown-domain')

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'POST retry_auto_ssl' do
    before do
      pages_domain.update!(auto_ssl_enabled: true, auto_ssl_failed: true)
    end

    let(:params) { request_params.merge(id: pages_domain.domain) }

    it 'calls retry service and redirects' do
      expect_next_instance_of(::Pages::Domains::RetryAcmeOrderService, pages_domain) do |service|
        expect(service).to receive(:execute)
      end

      post :retry_auto_ssl, params: params

      expect(response).to redirect_to project_pages_domain_path(project, pages_domain)
    end
  end

  describe 'DELETE destroy' do
    it "deletes the pages domain" do
      expect { delete(:destroy, params: request_params.merge(id: pages_domain.domain)) }
        .to change(PagesDomain, :count).by(-1)
        .and publish_event(::Pages::Domains::PagesDomainDeletedEvent)
        .with(
          project_id: project.id,
          namespace_id: project.namespace.id,
          root_namespace_id: project.root_namespace.id,
          domain_id: pages_domain.id,
          domain: pages_domain.domain
        )

      expect(response).to redirect_to(project_pages_path(project))
    end
  end

  describe 'DELETE #clean_certificate' do
    subject do
      delete(:clean_certificate, params: request_params.merge(id: pages_domain.domain))
    end

    it 'redirects to show page' do
      subject

      expect(response).to redirect_to(project_pages_domain_path(project, pages_domain))
    end

    it 'publishes PagesDomainUpdatedEvent event' do
      expect { subject }
        .to publish_event(::Pages::Domains::PagesDomainUpdatedEvent)
        .with(
          project_id: project.id,
          namespace_id: project.namespace.id,
          root_namespace_id: project.root_namespace.id,
          domain_id: pages_domain.id,
          domain: pages_domain.domain
        )
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

      it 'does not publish PagesDomainUpdatedEvent event' do
        expect { subject }
          .to not_publish_event(::Pages::Domains::PagesDomainUpdatedEvent)
      end

      it 'redirects to show page with a flash message' do
        subject

        expect(flash[:alert]).to include('Certificate')
        expect(flash[:alert]).to include('Key')
        expect(response).to redirect_to(project_pages_domain_path(project, pages_domain))
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

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'GET new' do
      it 'returns 404 status' do
        get :new, params: request_params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'POST create' do
      it "returns 404 status" do
        post(:create, params: request_params.merge(pages_domain: pages_domain_params))

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'DELETE destroy' do
      it "deletes the pages domain" do
        delete(:destroy, params: request_params.merge(id: pages_domain.domain))

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
