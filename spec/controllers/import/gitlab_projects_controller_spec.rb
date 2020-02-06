# frozen_string_literal: true

require 'spec_helper'

describe Import::GitlabProjectsController do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:user) { namespace.owner }
  let(:file) { fixture_file_upload('spec/fixtures/project_export.tar.gz', 'text/plain') }

  before do
    sign_in(user)
  end

  describe 'POST create' do
    context 'with an invalid path' do
      it 'redirects with an error' do
        post :create, params: { namespace_id: namespace.id, path: '/test', file: file }

        expect(flash[:alert]).to start_with('Project could not be imported')
        expect(response).to have_gitlab_http_status(:found)
      end

      it 'redirects with an error when a relative path is used' do
        post :create, params: { namespace_id: namespace.id, path: '../test', file: file }

        expect(flash[:alert]).to start_with('Project could not be imported')
        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'with a valid path' do
      it 'redirects to the new project path' do
        post :create, params: { namespace_id: namespace.id, path: 'test', file: file }

        expect(flash[:notice]).to include('is being imported')
        expect(response).to have_gitlab_http_status(:found)
      end
    end

    it_behaves_like 'project import rate limiter'
  end
end
