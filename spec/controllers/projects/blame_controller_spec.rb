# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BlameController, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user)    { create(:user, maintainer_of: project) }

  before do
    sign_in(user)

    controller.instance_variable_set(:@project, project)
  end

  shared_examples 'blame_response' do
    context 'valid branch, valid file' do
      let(:id) { 'master/files/ruby/popen.rb' }

      it { is_expected.to respond_with(:success) }
    end

    context 'valid branch, invalid file' do
      let(:id) { 'master/files/ruby/invalid-path.rb' }

      it 'redirects' do
        expect(subject).to redirect_to("/#{project.full_path}/-/tree/master")
      end
    end

    context 'valid branch, binary file' do
      let(:id) { 'master/files/images/logo-black.png' }

      it 'redirects' do
        expect(subject).to redirect_to("/#{project.full_path}/-/blob/master/files/images/logo-black.png")
      end
    end

    context 'invalid branch, valid file' do
      let(:id) { 'invalid-branch/files/ruby/missing_file.rb' }

      it { is_expected.to respond_with(:not_found) }
    end

    context 'when ref includes a newline' do
      let(:id) { "\n" }

      it 'returns 404' do
        is_expected.to respond_with(:not_found)
      end
    end
  end

  describe 'GET show' do
    render_views

    let(:params) { { namespace_id: project.namespace, project_id: project, id: id } }
    let(:request) { get :show, params: params }

    context 'with a valid ref and path' do
      before do
        request
      end

      it_behaves_like 'blame_response'
    end

    context 'when redirecting to the blob viewer' do
      let(:id) { 'master/files/ruby/popen.rb' }

      it 'does not load the blame' do
        expect(controller).not_to receive(:load_blame)

        request

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'renders a client-side redirect to the blob page with blame=1' do
        request

        expect(response.body).to include("/#{project.full_path}/-/blob/master/files/ruby/popen.rb?blame=1")
        expect(response.body).to include('window.location.replace')
        expect(response.body).not_to include('blame-table')
      end

      context 'when ref_type is given' do
        let(:params) { super().merge(ref_type: 'heads') }

        it 'includes ref_type in the redirect URL' do
          request

          expect(response.body).to include('ref_type=heads')
          expect(response.body).to include('blame=1')
        end
      end

      context 'when ignore_revs is given' do
        let(:params) { super().merge(ignore_revs: 'true') }

        it 'includes ignore_revs in the redirect URL' do
          request

          expect(response.body).to include('ignore_revs=true')
          expect(response.body).to include('blame=1')
        end
      end
    end
  end

  describe 'GET page' do
    render_views

    before do
      get :page, params: { namespace_id: project.namespace, project_id: project, id: id }
    end

    it_behaves_like 'blame_response'
  end

  describe 'GET streaming' do
    render_views

    before do
      get :streaming, params: { namespace_id: project.namespace, project_id: project, id: id }
    end

    it_behaves_like 'blame_response'
  end

  describe 'when gitaly is unavailable' do
    let(:id) { 'master/files/ruby/popen.rb' }

    before do
      allow(Gitlab::Git::Commit).to receive(:find)
        .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
    end

    it 'returns 503' do
      get :show, params: { namespace_id: project.namespace, project_id: project, id: id }

      expect(response).to have_gitlab_http_status(:service_unavailable)
    end

    it 'tracks the exception' do
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(Gitlab::Git::CommandError))

      get :show, params: { namespace_id: project.namespace, project_id: project, id: id }
    end
  end
end
