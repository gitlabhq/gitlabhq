# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BlobController, feature_category: :source_code_management do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :public, :repository) }
  let(:mutable_project) { create(:project, :public, :repository) }

  describe "GET show" do
    let_it_be(:head_sha) { project.repository.commit.id }

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
        let(:path) { 'README.md' }
        let(:id) { "#{ref}/#{path}" }

        it_behaves_like '#set_is_ambiguous_ref when ref is ambiguous'
      end

      describe '#set_is_ambiguous_ref with no ambiguous ref' do
        let(:id) { 'master/invalid-path.rb' }

        it_behaves_like '#set_is_ambiguous_ref when ref is not ambiguous'
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

      context 'valid branch, valid file, correct ref_type' do
        let(:id) { 'master/README.md' }
        let(:ref_type) { 'heads' }

        it { is_expected.to respond_with(:success) }
      end

      context 'valid branch, valid file, wrong ref_type' do
        let(:id) { 'master/README.md' }
        let(:ref_type) { 'tags' }

        it { is_expected.to respond_with(:not_found) }
      end

      context 'sha ref, valid file' do
        let(:id) { "#{head_sha}/README.md" }

        it { is_expected.to respond_with(:success) }
      end

      context 'wrong sha ref, valid file' do
        let(:id) { '0000000000000000000000000000000000000000/README.md' }

        it { is_expected.to respond_with(:not_found) }
      end

      context 'sha ref, valid file, non-empty ref_type' do
        let(:id) { "#{head_sha}/README.md" }
        let(:ref_type) { 'heads' }

        it { is_expected.to respond_with(:not_found) }
      end

      context 'when default branch was renamed' do
        let_it_be_with_reload(:project) { create(:project, :public, :repository, previous_default_branch: 'old-default-branch') }

        context "renamed default branch, valid file" do
          let(:id) { 'old-default-branch/README.md' }

          it { is_expected.to redirect_to("/#{project.full_path}/-/blob/#{project.default_branch}/README.md") }
        end

        context "renamed default branch, invalid file" do
          let(:id) { 'old-default-branch/invalid-path.rb' }

          it { is_expected.to redirect_to("/#{project.full_path}/-/blob/#{project.default_branch}/invalid-path.rb") }
        end
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
          get :show, params: params, format: :json
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
          get :show, params: { namespace_id: project.namespace, project_id: project, id: id, ref_type: 'heads', viewer: 'none' }, format: :json
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
        get :show, params: params

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

    context 'when rendering a GitLab CI file' do
      let_it_be(:files_to_create) do
        {
          '.gitlab-ci.yml' => <<~YAML
            rspec:
              script: exit 0
          YAML
        }
      end

      let_it_be(:project) { create(:project, :public, :custom_repo, files: files_to_create) }

      let(:id) { "#{project.default_branch}/.gitlab-ci.yml" }

      it 'displays the validation section' do
        request

        is_expected.to respond_with(:success)

        expect(response.body).to include('Validating GitLab CI configuration')
      end

      context 'when the blob ref is a commit SHA' do
        let(:id) { "#{project.repository.commit.id}/.gitlab-ci.yml" }

        it 'does not display the validation section' do
          request

          is_expected.to respond_with(:success)

          expect(response.body).not_to include('Validating GitLab CI configuration')
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
        expect(response).to have_gitlab_http_status(:ok)
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
        expect(response).to have_gitlab_http_status(:ok)
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
      mutable_project.add_maintainer(user)

      sign_in(user)
    end

    it 'redirects to blob' do
      put :update, params: default_params

      expect(response).to redirect_to(blob_after_edit_path)
    end

    context 'when file is renamed' do
      let(:default_params) do
        {
          namespace_id: mutable_project.namespace,
          project_id: mutable_project,
          id: 'master/CHANGELOG',
          file_path: 'CHANGELOG2',
          branch_name: 'master',
          content: 'Added changes',
          commit_message: 'Rename CHANGELOG'
        }
      end

      it 'redirects to blob' do
        put :update, params: default_params

        expect(response).to redirect_to(project_blob_path(mutable_project, 'master/CHANGELOG2'))
        expect(assigns[:commit_params]).to include(file_path: 'CHANGELOG2', previous_path: 'CHANGELOG')
      end
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
                target_project_id: project.id,
                source_branch: "fork-test-1",
                target_branch: "master"
              }
            )
          )
        end
      end
    end

    context 'events tracking' do
      let(:target_event) { 'g_edit_by_sfe' }

      subject(:request) { put :update, params: default_params }

      it_behaves_like 'internal event tracking' do
        let(:namespace) { project.namespace.reload }
        let(:event) { target_event }
      end
    end

    context 'when the commit fails' do
      before do
        allow_next_instance_of(Files::UpdateService) do |instance|
          allow(instance).to receive(:execute).and_return({ status: :error, message: 'Invalid commit message' })
        end
      end

      it 'responds with 422 Unprocessable Entity and sets flash alert' do
        put :update, params: default_params, format: :json

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Invalid commit message')
        expect(json_response['filePath']).to eq(project_blob_path(project, 'master/CHANGELOG'))
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
        expect_next_instance_of(Files::DeleteService) do |instance|
          expect(instance).to receive(:execute).and_return({ status: :success })
        end

        delete :destroy, params: default_params

        expect(response).to redirect_to(after_delete_path)
      end

      context 'when a validation failure occurs' do
        let(:failure_path) { project_blob_path(project, default_params[:id]) }

        render_views

        it 'redirects to a valid page' do
          expect_next_instance_of(Files::DeleteService) do |instance|
            expect(instance).to receive(:validate!).and_raise(Commits::CreateService::ValidationError, "validation error")
          end

          delete :destroy, params: default_params

          expect(response).to redirect_to(failure_path)
        end
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

  describe 'POST preview' do
    subject(:request) { post :preview, params: default_params }

    let(:user) { create(:user) }
    let(:filename) { 'preview.md' }
    let(:default_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: "#{project.default_branch}/#{filename}",
        content: "Bar\n"
      }
    end

    before do
      project.add_developer(user)
      sign_in(user)

      project.repository.create_file(
        project.creator,
        filename,
        "Foo\n",
        message: 'Test',
        branch_name: project.default_branch
      )
    end

    it 'is successful' do
      request

      expect(response).to be_successful
    end
  end

  describe 'POST create' do
    let_it_be(:user) { create(:user) }

    let(:target_event) { 'g_edit_by_sfe' }
    let(:default_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: 'master',
        branch_name: 'master',
        file_name: 'docs/EXAMPLE_FILE',
        content: 'Added changes',
        commit_message: 'Create CHANGELOG'
      }
    end

    before do
      project.add_developer(user)

      sign_in(user)
    end

    subject(:request) { post :create, params: default_params }

    it_behaves_like 'internal event tracking' do
      let(:namespace) { project.namespace.reload }
      let(:event) { target_event }
    end

    it 'redirects to blob' do
      request

      expect(response).to redirect_to(project_blob_path(project, 'master/docs/EXAMPLE_FILE'))
    end

    context 'when file_name is missing' do
      let(:default_params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          id: 'master',
          branch_name: 'master',
          content: 'Added changes',
          commit_message: 'Create CHANGELOG'
        }
      end

      render_views

      it 'renders an error message' do
        request

        expect(response).to be_successful
        expect(response).to render_template(:new)
        expect(response.body).to include('You must provide a file path')
      end
    end
  end
end
