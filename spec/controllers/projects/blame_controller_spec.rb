# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BlameController, feature_category: :source_code_management do
  include RepoHelpers
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user)    { create(:user) }

  before do
    sign_in(user)

    project.add_maintainer(user)
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

    let(:params) { { namespace_id: project.namespace, project_id: project, id: id, ignore_revs: ignore_revs } }
    let(:ignore_revs) { nil }
    let(:request) { get :show, params: params }

    context 'when ignore_revs is nil' do
      before do
        request
      end

      it_behaves_like 'blame_response'
    end

    context 'when inline_blame feature flag is enabled' do
      let(:id) { 'master/files/ruby/popen.rb' }

      before do
        stub_feature_flags(inline_blame: project)
      end

      it 'does not call load_blame' do
        expect(controller).not_to receive(:load_blame)
        get :show, params: { namespace_id: project.namespace, project_id: project, id: id }
      end

      it 'responds with success' do
        get :show, params: { namespace_id: project.namespace, project_id: project, id: id }
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when ignore_revs is true' do
      let(:ignore_revs) { true }
      let(:id) { 'master/files/ruby/popen.rb' }

      before do
        stub_feature_flags(inline_blame: false)
      end

      shared_examples_for 'redirecting ignore rev with flash' do |flash_message|
        context 'and there are other params' do
          let(:params) { super().merge(ref_type: 'heads') }

          it 'redirects with those params' do
            request

            expect(controller).to redirect_to("/#{project.full_path}/-/blame/#{id}?ref_type=heads")
          end
        end

        it 'redirects with flash' do
          request

          expect(controller).to redirect_to("/#{project.full_path}/-/blame/#{id}?ref_type=heads")
          expect(flash[:notice]).to eq(flash_message)
        end
      end

      context 'and there is no ignore revs file' do
        it_behaves_like 'redirecting ignore rev with flash', '.git-blame-ignore-revs is not a file'
      end

      context 'and there is an ignore revs file' do
        let(:project_files) do
          { Gitlab::Blame::IGNORE_REVS_FILE_NAME => file_content }
        end

        around do |example|
          create_and_delete_files(project, project_files) do
            example.run
          end
        end

        context 'and it is malformed' do
          let(:file_content) { 'malformed content' }

          it_behaves_like 'redirecting ignore rev with flash', 'Malformed .git-blame-ignore-revs'
        end

        context 'and it contains commit ids' do
          let(:file_content) { project.commit.id }

          it 'responds successfully' do
            request
            is_expected.to respond_with(:success)
          end
        end
      end
    end
  end

  describe 'GET show with inline_blame feature flag' do
    render_views

    let(:id) { 'master/files/ruby/popen.rb' }

    context 'when inline_blame flag is enabled' do
      before do
        stub_feature_flags(inline_blame: project)
      end

      it 'renders a client-side redirect to the blob page with blame=1' do
        get :show, params: { namespace_id: project.namespace, project_id: project, id: id }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include("/#{project.full_path}/-/blob/master/files/ruby/popen.rb?blame=1")
        expect(response.body).to include('window.location.replace')
        expect(response.body).not_to include('blame-table')
      end

      it 'includes ref_type in the redirect URL when provided' do
        get :show, params: { namespace_id: project.namespace, project_id: project, id: id, ref_type: 'heads' }

        expect(response.body).to include('ref_type=heads')
        expect(response.body).to include('blame=1')
      end
    end

    context 'when inline_blame flag is disabled' do
      before do
        stub_feature_flags(inline_blame: false)
      end

      it 'renders the legacy blame page' do
        get :show, params: { namespace_id: project.namespace, project_id: project, id: id }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('blame-table')
        expect(response.body).not_to include('window.location.replace')
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
