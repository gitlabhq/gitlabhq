require 'spec_helper'

describe Projects::PagesDomainsController do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }

  let(:request_params) do
    {
      namespace_id: project.namespace,
      project_id: project
    }
  end

  before do
    sign_in(user)
    project.team << [user, :master]
  end

  describe 'GET show' do
    let!(:pages_domain)   { create(:pages_domain, project: project) }

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
    let(:pages_domain_params) do
      build(:pages_domain, :with_certificate, :with_key).slice(:key, :certificate, :domain)
    end

    it "creates a new pages domain" do
      expect do
        post(:create, request_params.merge(pages_domain: pages_domain_params))
      end.to change { PagesDomain.count }.by(1)

      expect(response).to redirect_to(namespace_project_pages_path(project.namespace, project))
    end
  end

  describe 'DELETE destroy' do
    let!(:pages_domain)   { create(:pages_domain, project: project) }

    it "deletes the pages domain" do
      expect do
        delete(:destroy, request_params.merge(id: pages_domain.domain))
      end.to change { PagesDomain.count }.by(-1)

      expect(response).to redirect_to(namespace_project_pages_path(project.namespace, project))
    end
  end
end
