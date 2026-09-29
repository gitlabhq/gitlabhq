# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CommitsController, feature_category: :source_code_management do
  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  let(:repository) { project.repository }

  context 'unauthenticated user' do
    let_it_be_with_reload(:project) { create(:project, :repository, :public) }

    context 'GET show' do
      context 'without path' do
        let(:id) { "master" }

        it 'is successful' do
          get :show, params: { namespace_id: project.namespace, project_id: project, id: id }

          expect(assigns(:commits)).to be_present
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context "with path provided" do
        let(:id) { "master/README.md" }

        it "requires authentication" do
          get :show, params: { namespace_id: project.namespace, project_id: project, id: id }

          expect(assigns(:commits)).to be_nil
          expect(response).to redirect_to(new_user_session_path)
        end

        context 'when "require_login_for_commit_tree" FF is disabled' do
          before do
            stub_feature_flags(require_login_for_commit_tree: false)
          end

          it 'is successful' do
            get :show, params: { namespace_id: project.namespace, project_id: project, id: id }

            expect(assigns(:commits)).to be_present
            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end

    context 'GET signatures' do
      context 'without path' do
        let(:id) { "master" }

        it 'is successful' do
          get :signatures, params: { namespace_id: project.namespace, project_id: project, id: id, format: :json }

          expect(assigns(:commits)).to be_present
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context "with path provided" do
        let(:id) { "master/README.md" }

        it "requires authentication" do
          get :signatures, params: { namespace_id: project.namespace, project_id: project, id: id, format: :json }

          expect(assigns(:commits)).to be_nil
          expect(response).to have_gitlab_http_status(:unauthorized)
        end

        context 'when "require_login_for_commit_tree" FF is disabled' do
          before do
            stub_feature_flags(require_login_for_commit_tree: false)
          end

          it 'is successful' do
            get :signatures, params: { namespace_id: project.namespace, project_id: project, id: id, format: :json }

            expect(assigns(:commits)).to be_present
            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end
  end

  context 'signed in' do
    before do
      sign_in(user)
    end

    describe "GET commits_root" do
      context "no ref is provided" do
        it 'redirects to the default branch of the project' do
          get :commits_root, params: { namespace_id: project.namespace, project_id: project }

          expect(response).to redirect_to project_commits_path(project)
        end
      end
    end

    describe "GET show" do
      let(:params) { { namespace_id: project.namespace, project_id: project, id: id, ref_type: ref_type } }
      let(:ref_type) { nil }
      let(:request) do
        get(:show, params: params)
      end

      render_views

      context 'with file path' do
        include_context 'with ambiguous refs for controllers'

        before do
          request
        end

        context 'when the ref is ambiguous' do
          let(:ref) { 'ambiguous_ref' }
          let(:ref_type) { 'tags' }
          let(:path) { 'README.md' }
          let(:id) { "#{ref}/#{path}" }

          it_behaves_like '#set_is_ambiguous_ref when ref is ambiguous'
        end

        describe '#set_is_ambiguous_ref with no ambiguous ref' do
          let(:id) { 'master/README.md' }

          it_behaves_like '#set_is_ambiguous_ref when ref is not ambiguous'
        end

        context "valid branch, valid file" do
          let(:id) { 'master/README.md' }

          it { is_expected.to respond_with(:success) }
        end

        context "HEAD, valid file" do
          let(:id) { 'HEAD/README.md' }

          it { is_expected.to respond_with(:success) }
        end

        context "valid branch, invalid file" do
          let(:id) { 'master/invalid-path.rb' }

          it { is_expected.to redirect_to project_tree_path(project, 'master', '/') }
        end

        context "invalid branch, valid file" do
          let(:id) { 'invalid-branch/README.md' }

          it { is_expected.to respond_with(:not_found) }
        end

        context "branch with invalid format, valid file" do
          let(:id) { 'branch with space/README.md' }

          it { is_expected.to respond_with(:not_found) }
        end
      end

      context "valid branch, whitespace-only file that exists" do
        let_it_be_with_reload(:project) { create(:project, :repository, maintainers: user) }
        let(:id) { 'master/ ' }

        before do
          project.repository.create_file(
            user, ' ', 'content',
            message: 'Add file with space name', branch_name: 'master'
          )
          request
        end

        it { is_expected.to respond_with(:success) }
      end

      context 'when branch has only empty commits' do
        let(:id) { 'empty-branch' }

        it 'allows to see commits' do
          request

          is_expected.to respond_with(:success)
        end
      end

      describe 'loading tags' do
        it 'loads tags for commits' do
          expect_next_instance_of(CommitCollection) do |collection|
            expect(collection).to receive(:load_tags)
          end

          get :show, params: { namespace_id: project.namespace, project_id: project, id: 'master/README.md' }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when tag has a non-ASCII encoding' do
        before do
          repository.add_tag(user, 'tést', 'master')
        end

        it 'does not raise an exception' do
          get :show, params: { namespace_id: project.namespace, project_id: project, id: 'master' }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context "when the ref name ends in .atom" do
        context "when the ref does not exist with the suffix" do
          before do
            get :show, params: { namespace_id: project.namespace, project_id: project, id: "master.atom" }
          end

          it "renders as atom" do
            expect(response).to be_successful
            expect(response.body).to include('<entry>')
            expect(response.media_type).to eq('application/atom+xml')
          end

          it 'renders summary with type=html' do
            expect(response.body).to include('<summary type="html">')
          end
        end

        context 'when ref_type is provided' do
          let(:ref_type) { 'heads' }

          before do
            get :show,
              params: { namespace_id: project.namespace, project_id: project, id: "master.atom", ref_type: ref_type }
          end

          it "renders as atom" do
            expect(response).to be_successful
            expect(response.body).to include('<entry>')
            expect(response.media_type).to eq('application/atom+xml')
          end

          context 'when there is no reference for provided ref_type' do
            let(:ref_type) { 'tags' }

            it { is_expected.to respond_with(:not_found) }
          end
        end

        context "when the ref exists with the suffix" do
          before do
            commit = project.repository.commit('master')

            allow_any_instance_of(Repository).to receive(:commit).and_call_original
            allow_any_instance_of(Repository).to receive(:commit).with('master.atom').and_return(commit)

            get :show, params: {
              namespace_id: project.namespace,
              project_id: project,
              id: "master.atom"
            }
          end

          it "renders as HTML" do
            expect(response).to be_successful
            expect(response.media_type).to eq('text/html')
          end
        end

        context 'when the ref does not exist' do
          before do
            get(:show, params: {
              namespace_id: project.namespace,
              project_id: project,
              id: 'unknown.atom'
            })
          end

          it 'returns 404 page' do
            expect(response).to be_not_found
          end
        end
      end

      context 'with markdown cache' do
        it 'preloads markdown cache for commits' do
          expect(Commit).to receive(:preload_markdown_cache!).and_call_original

          get :show, params: { namespace_id: project.namespace, project_id: project, id: 'master/README.md' }
        end
      end

      context 'when gitaly is unavailable' do
        before do
          allow_next_instance_of(Repository) do |repository|
            allow(repository).to receive(:commits)
              .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
          end
        end

        it 'returns 503 and sets gitaly_unavailable' do
          get :show, params: { namespace_id: project.namespace, project_id: project, id: 'master' }

          expect(response).to have_gitlab_http_status(:service_unavailable)
          expect(assigns(:gitaly_unavailable)).to be true
        end
      end
    end

    describe "GET /commits/:id/signatures" do
      render_views

      let(:send_request) do
        get :signatures, params: {
          namespace_id: project.namespace,
          project_id: project,
          id: id
        }, format: :json
      end

      before do
        expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original unless id.include?(' ')
      end

      context "valid branch" do
        let(:id) { 'master' }

        it 'returns a successful response' do
          send_request

          is_expected.to respond_with(:success)
        end
      end

      context "invalid branch format" do
        let(:id) { 'some branch' }

        it 'returns a not found response' do
          send_request

          is_expected.to respond_with(:not_found)
        end
      end

      context 'with signature message' do
        let(:id) { 'master' }
        let(:commit) { repository.commit('5937ac0a7beb003549fc5fd26fc247adbce4a52e') }
        let(:signature) { json_response['signatures'].find { |s| s['commit_sha'] == commit.id } }

        it 'returns a signature message' do
          send_request

          expect(signature).to be_present

          expect(signature['html']).to include('GPG Key ID')
          expect(signature['html']).to include('This commit was signed with an unverified signature')
        end

        context 'when commit has an unsupported signature type' do
          before do
            allow(Gitlab::Gpg::Commit).to receive(:new).and_call_original
            expect_next_instance_of(Gitlab::Gpg::Commit, commit) do |gpg_commit|
              expect(gpg_commit).to receive(:signature).and_return(nil)
            end
          end

          it 'returns a unsupported signature message' do
            send_request

            expect(signature).to be_present
            expect(signature['html']).to include('Unsupported signature')
          end
        end
      end
    end
  end
end
