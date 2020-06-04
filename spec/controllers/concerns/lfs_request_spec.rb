# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LfsRequest do
  include ProjectForksHelper

  controller(Repositories::GitHttpClientController) do
    # `described_class` is not available in this context
    include LfsRequest

    def show
      head :ok
    end

    def project
      @project ||= Project.find_by(id: params[:id])
    end

    def download_request?
      true
    end

    def upload_request?
      false
    end

    def ci?
      false
    end
  end

  let(:project) { create(:project, :public) }

  before do
    stub_lfs_setting(enabled: true)
  end

  context 'user is authenticated without access to lfs' do
    before do
      allow(controller).to receive(:authenticate_user)
      allow(controller).to receive(:authentication_result) do
        Gitlab::Auth::Result.new
      end
    end

    context 'with access to the project' do
      it 'returns 403' do
        get :show, params: { id: project.id }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'without access to the project' do
      context 'project does not exist' do
        it 'returns 404' do
          get :show, params: { id: 'does not exist' }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'project is private' do
        let(:project) { create(:project, :private) }

        it 'returns 404' do
          get :show, params: { id: project.id }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
