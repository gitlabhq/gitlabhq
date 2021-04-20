# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IncidentsController do
  let_it_be_with_refind(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:anonymous) { nil }

  before_all do
    project.add_guest(guest)
    project.add_developer(developer)
  end

  before do
    sign_in(user) if user
  end

  subject { make_request }

  shared_examples 'not found' do
    include_examples 'returning response status', :not_found
  end

  shared_examples 'login required' do
    it 'redirects to the login page' do
      subject

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'GET #index' do
    def make_request
      get :index, params: project_params
    end

    let(:user) { developer }

    it 'shows the page' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
    end

    context 'when user is unauthorized' do
      let(:user) { anonymous }

      it_behaves_like 'login required'
    end

    context 'when user is a guest' do
      let(:user) { guest }

      it 'shows the page' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end
  end

  describe 'GET #show' do
    def make_request
      get :show, params: project_params(id: resource)
    end

    let_it_be(:resource) { create(:incident, project: project) }

    let(:user) { developer }

    it 'renders incident page' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:show)

      expect(assigns(:incident)).to be_present
      expect(assigns(:incident).author.association(:status)).to be_loaded
      expect(assigns(:issue)).to be_present
      expect(assigns(:noteable)).to eq(assigns(:incident))
    end

    context 'with non existing id' do
      let(:resource) { non_existing_record_id }

      it_behaves_like 'not found'
    end

    context 'for issue' do
      let_it_be(:resource) { create(:issue, project: project) }

      it_behaves_like 'not found'
    end

    context 'when user is a guest' do
      let(:user) { guest }

      it 'shows the page' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
      end
    end

    context 'when unauthorized' do
      let(:user) { anonymous }

      it_behaves_like 'login required'
    end
  end

  private

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end
