# frozen_string_literal: true

require 'spec_helper'

describe LfsRequest do
  include ProjectForksHelper

  controller(Projects::GitHttpClientController) do
    # `described_class` is not available in this context
    include LfsRequest

    def show
      storage_project

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

  describe '#storage_project' do
    it 'assigns the project as storage project' do
      get :show, params: { id: project.id }

      expect(assigns(:storage_project)).to eq(project)
    end

    it 'assigns the source of a forked project' do
      forked_project = fork_project(project)

      get :show, params: { id: forked_project.id }

      expect(assigns(:storage_project)).to eq(project)
    end
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

        expect(response.status).to eq(403)
      end
    end

    context 'without access to the project' do
      context 'project does not exist' do
        it 'returns 404' do
          get :show, params: { id: 'does not exist' }

          expect(response.status).to eq(404)
        end
      end

      context 'project is private' do
        let(:project) { create(:project, :private) }

        it 'returns 404' do
          get :show, params: { id: project.id }

          expect(response.status).to eq(404)
        end
      end
    end
  end
end
