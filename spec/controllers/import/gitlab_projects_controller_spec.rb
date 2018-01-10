require 'spec_helper'

describe Import::GitlabProjectsController do
  set(:namespace) { create(:namespace) }
  set(:user) { namespace.owner }
  let(:file) { fixture_file_upload(Rails.root + 'spec/fixtures/doc_sample.txt', 'text/plain') }

  before do
    sign_in(user)
  end

  describe 'POST create' do
    context 'with an invalid path' do
      it 'redirects with an error' do
        post :create, namespace_id: namespace.id, path: '/test', file: file

        expect(flash[:alert]).to start_with('Project could not be imported')
        expect(response).to have_gitlab_http_status(302)
      end

      it 'redirects with an error when a relative path is used' do
        post :create, namespace_id: namespace.id, path: '../test', file: file

        expect(flash[:alert]).to start_with('Project could not be imported')
        expect(response).to have_gitlab_http_status(302)
      end
    end

    context 'with a valid path' do
      it 'redirects to the new project path' do
        post :create, namespace_id: namespace.id, path: 'test', file: file

        expect(flash[:notice]).to include('is being imported')
        expect(response).to have_gitlab_http_status(302)
      end
    end
  end
end
