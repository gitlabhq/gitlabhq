# frozen_string_literal: true

require 'spec_helper'

describe Projects::BlobController do
  include ProjectForksHelper

  let(:project) { create(:project, :public, :repository) }

  describe "GET show" do
    render_views

    context 'with file path' do
      before do
        expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original

        get(:show,
            params: {
              namespace_id: project.namespace,
              project_id: project,
              id: id
            })
      end

      context "valid branch, valid file" do
        let(:id) { 'master/README.md' }

        it { is_expected.to respond_with(:success) }
      end

      context "valid branch, invalid file" do
        let(:id) { 'master/invalid-path.rb' }

        it 'redirects' do
          expect(subject)
              .to redirect_to("/#{project.full_path}/-/tree/master")
        end
      end

      context "invalid branch, valid file" do
        let(:id) { 'invalid-branch/README.md' }

        it { is_expected.to respond_with(:not_found) }
      end

      context "binary file" do
        let(:id) { 'binary-encoding/encoding/binary-1.bin' }

        it { is_expected.to respond_with(:success) }
      end

      context "Markdown file" do
        let(:id) { 'master/README.md' }

        it { is_expected.to respond_with(:success) }
      end
    end

    context 'with file path and JSON format' do
      context "valid branch, valid file" do
        let(:id) { 'master/README.md' }

        before do
          get(:show,
              params: {
                namespace_id: project.namespace,
                project_id: project,
                id: id
              },
              format: :json)
        end

        it do
          expect(response).to be_ok
          expect(json_response).to have_key 'html'
          expect(json_response).to have_key 'raw_path'
        end
      end

      context "with viewer=none" do
        let(:id) { 'master/README.md' }

        before do
          get(:show,
              params: {
                namespace_id: project.namespace,
                project_id: project,
                id: id,
                viewer: 'none'
              },
              format: :json)
        end

        it do
          expect(response).to be_ok
          expect(json_response).not_to have_key 'html'
          expect(json_response).to have_key 'raw_path'
        end
      end
    end

    context 'with tree path' do
      before do
        get(:show,
            params: {
              namespace_id: project.namespace,
              project_id: project,
              id: id
            })
        controller.instance_variable_set(:@blob, nil)
      end

      context 'redirect to tree' do
        let(:id) { 'markdown/doc' }

        it 'redirects' do
          expect(subject)
            .to redirect_to("/#{project.full_path}/-/tree/markdown/doc")
        end
      end
    end
  end

  describe 'GET diff' do
    let(:user) { create(:user) }

    render_views

    def do_get(opts = {})
      params = { namespace_id: project.namespace,
                 project_id: project,
                 id: 'master/CHANGELOG' }
      get :diff, params: params.merge(opts)
    end

    before do
      project.add_maintainer(user)

      sign_in(user)
    end

    context 'when essential params are missing' do
      it 'renders nothing' do
        do_get

        expect(response.body).to be_blank
      end
    end

    context 'when essential params are present' do
      context 'when rendering for commit' do
        it 'renders the diff content' do
          do_get(since: 1, to: 5, offset: 10)

          expect(response.body).to be_present
        end
      end

      context 'when rendering for merge request' do
        let(:presenter) { double(:presenter, diff_lines: diff_lines) }
        let(:diff_lines) do
          Array.new(3, Gitlab::Diff::Line.new('plain', nil, nil, nil, nil, rich_text: 'rich'))
        end

        before do
          allow(Blobs::UnfoldPresenter).to receive(:new).and_return(presenter)
        end

        it 'renders diff context lines Gitlab::Diff::Line array' do
          do_get(since: 1, to: 2, offset: 0, from_merge_request: true)

          lines = json_response

          expect(lines.size).to eq(diff_lines.size)
          lines.each do |line|
            expect(line).to have_key('type')
            expect(line['text']).to eq('plain')
            expect(line['rich_text']).to eq('rich')
          end
        end

        it 'handles full being true' do
          do_get(full: true, from_merge_request: true)

          lines = json_response

          expect(lines.size).to eq(diff_lines.size)
        end
      end
    end
  end

  describe 'GET edit' do
    let(:default_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: 'master/CHANGELOG'
      }
    end

    context 'anonymous' do
      before do
        get :edit, params: default_params
      end

      it 'redirects to sign in and returns' do
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as guest' do
      let(:guest) { create(:user) }

      before do
        sign_in(guest)
        get :edit, params: default_params
      end

      it 'redirects to blob show' do
        expect(response).to redirect_to(project_blob_path(project, 'master/CHANGELOG'))
      end
    end

    context 'as developer' do
      let(:developer) { create(:user) }

      before do
        project.add_developer(developer)
        sign_in(developer)
        get :edit, params: default_params
      end

      it 'redirects to blob show' do
        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'as maintainer' do
      let(:maintainer) { create(:user) }

      before do
        project.add_maintainer(maintainer)
        sign_in(maintainer)
        get :edit, params: default_params
      end

      it 'redirects to blob show' do
        expect(response).to have_gitlab_http_status(200)
      end
    end
  end

  describe 'PUT update' do
    let(:user) { create(:user) }
    let(:default_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: 'master/CHANGELOG',
        branch_name: 'master',
        content: 'Added changes',
        commit_message: 'Update CHANGELOG'
      }
    end

    def blob_after_edit_path
      project_blob_path(project, 'master/CHANGELOG')
    end

    before do
      project.add_maintainer(user)

      sign_in(user)
    end

    it 'redirects to blob' do
      put :update, params: default_params

      expect(response).to redirect_to(blob_after_edit_path)
    end

    context '?from_merge_request_iid' do
      let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
      let(:mr_params) { default_params.merge(from_merge_request_iid: merge_request.iid) }

      it 'redirects to MR diff' do
        put :update, params: mr_params

        after_edit_path = diffs_project_merge_request_path(project, merge_request)
        file_anchor = "##{Digest::SHA1.hexdigest('CHANGELOG')}"
        expect(response).to redirect_to(after_edit_path + file_anchor)
      end

      context "when user doesn't have access" do
        before do
          other_project = create(:project, :repository)
          merge_request.update!(source_project: other_project, target_project: other_project)
        end

        it "redirects to blob" do
          put :update, params: mr_params

          expect(response).to redirect_to(blob_after_edit_path)
        end
      end
    end

    context 'when user has forked project' do
      let!(:forked_project) { fork_project(project, guest, namespace: guest.namespace, repository: true) }
      let(:guest) { create(:user) }

      before do
        sign_in(guest)
      end

      context 'when editing on the fork' do
        before do
          default_params[:namespace_id] = forked_project.namespace
          default_params[:project_id] = forked_project
        end

        it 'redirects to blob', :sidekiq_might_not_need_inline do
          put :update, params: default_params

          expect(response).to redirect_to(project_blob_path(forked_project, 'master/CHANGELOG'))
        end
      end

      context 'when editing on the original repository' do
        it "redirects to forked project new merge request", :sidekiq_might_not_need_inline do
          default_params[:branch_name] = "fork-test-1"
          default_params[:create_merge_request] = 1

          put :update, params: default_params

          expect(response).to redirect_to(
            project_new_merge_request_path(
              forked_project,
              merge_request: {
                source_project_id: forked_project.id,
                target_project_id: project.id,
                source_branch: "fork-test-1",
                target_branch: "master"
              }
            )
          )
        end
      end
    end
  end

  describe 'DELETE destroy' do
    let(:user) { create(:user) }
    let(:project_root_path) { project_tree_path(project, 'master') }

    before do
      project.add_maintainer(user)

      sign_in(user)
    end

    context 'for a file in a subdirectory' do
      let(:default_params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          id: 'master/files/whitespace',
          original_branch: 'master',
          branch_name: 'master',
          commit_message: 'Delete whitespace'
        }
      end

      let(:after_delete_path) { project_tree_path(project, 'master/files') }

      it 'redirects to the sub directory' do
        delete :destroy, params: default_params

        expect(response).to redirect_to(after_delete_path)
      end
    end

    context 'if deleted file is the last one in a subdirectory' do
      let(:default_params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          id: 'master/bar/branch-test.txt',
          original_branch: 'master',
          branch_name: 'master',
          commit_message: 'Delete whitespace'
        }
      end

      it 'redirects to the project root' do
        delete :destroy, params: default_params

        expect(response).to redirect_to(project_root_path)
      end

      context 'when deleting a file in a branch other than master' do
        let(:default_params) do
          {
            namespace_id: project.namespace,
            project_id: project,
            id: 'binary-encoding/foo/bar/.gitkeep',
            original_branch: 'binary-encoding',
            branch_name: 'binary-encoding',
            commit_message: 'Delete whitespace'
          }
        end

        let(:after_delete_path) { project_tree_path(project, 'binary-encoding') }

        it 'redirects to the project root of the branch' do
          delete :destroy, params: default_params

          expect(response).to redirect_to(after_delete_path)
        end
      end
    end
  end
end
