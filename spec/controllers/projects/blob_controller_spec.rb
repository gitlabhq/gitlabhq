require 'rails_helper'

describe Projects::BlobController do
  let(:project) { create(:project, :public, :repository) }

  describe "GET show" do
    render_views

    context 'with file path' do
      before do
        get(:show,
            namespace_id: project.namespace,
            project_id: project,
            id: id)
      end

      context "valid branch, valid file" do
        let(:id) { 'master/README.md' }
        it { is_expected.to respond_with(:success) }
      end

      context "valid branch, invalid file" do
        let(:id) { 'master/invalid-path.rb' }
        it { is_expected.to respond_with(:not_found) }
      end

      context "invalid branch, valid file" do
        let(:id) { 'invalid-branch/README.md' }
        it { is_expected.to respond_with(:not_found) }
      end

      context "binary file" do
        let(:id) { 'binary-encoding/encoding/binary-1.bin' }
        it { is_expected.to respond_with(:success) }
      end
    end

    context 'with tree path' do
      before do
        get(:show,
            namespace_id: project.namespace,
            project_id: project,
            id: id)
        controller.instance_variable_set(:@blob, nil)
      end

      context 'redirect to tree' do
        let(:id) { 'markdown/doc' }
        it 'redirects' do
          expect(subject)
            .to redirect_to("/#{project.path_with_namespace}/tree/markdown/doc")
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
      get :diff, params.merge(opts)
    end

    before do
      project.team << [user, :master]

      sign_in(user)
    end

    context 'when essential params are missing' do
      it 'renders nothing' do
        do_get

        expect(response.body).to be_blank
      end
    end

    context 'when essential params are present' do
      it 'renders the diff content' do
        do_get(since: 1, to: 5, offset: 10)

        expect(response.body).to be_present
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
        get :edit, default_params
      end

      it 'redirects to sign in and returns' do
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as guest' do
      let(:guest) { create(:user) }

      before do
        sign_in(guest)
        get :edit, default_params
      end

      it 'redirects to blob show' do
        expect(response).to redirect_to(project_blob_path(project, 'master/CHANGELOG'))
      end
    end

    context 'as developer' do
      let(:developer) { create(:user) }

      before do
        project.team << [developer, :developer]
        sign_in(developer)
        get :edit, default_params
      end

      it 'redirects to blob show' do
        expect(response).to have_http_status(200)
      end
    end

    context 'as master' do
      let(:master) { create(:user) }

      before do
        project.team << [master, :master]
        sign_in(master)
        get :edit, default_params
      end

      it 'redirects to blob show' do
        expect(response).to have_http_status(200)
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
      project.team << [user, :master]

      sign_in(user)
    end

    it 'redirects to blob' do
      put :update, default_params

      expect(response).to redirect_to(blob_after_edit_path)
    end

    context '?from_merge_request_iid' do
      let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
      let(:mr_params) { default_params.merge(from_merge_request_iid: merge_request.iid) }

      it 'redirects to MR diff' do
        put :update, mr_params

        after_edit_path = diffs_project_merge_request_path(project, merge_request)
        file_anchor = "##{Digest::SHA1.hexdigest('CHANGELOG')}"
        expect(response).to redirect_to(after_edit_path + file_anchor)
      end

      context "when user doesn't have access" do
        before do
          other_project = create(:empty_project)
          merge_request.update!(source_project: other_project, target_project: other_project)
        end

        it "it redirect to blob" do
          put :update, mr_params

          expect(response).to redirect_to(blob_after_edit_path)
        end
      end
    end

    context 'when user has forked project' do
      let(:forked_project_link) { create(:forked_project_link, forked_from_project: project) }
      let!(:forked_project) { forked_project_link.forked_to_project }
      let(:guest) { forked_project.owner }

      before do
        sign_in(guest)
      end

      context 'when editing on the fork' do
        before do
          default_params[:namespace_id] = forked_project.namespace
          default_params[:project_id] = forked_project
        end

        it 'redirects to blob' do
          put :update, default_params

          expect(response).to redirect_to(project_blob_path(forked_project, 'master/CHANGELOG'))
        end
      end

      context 'when editing on the original repository' do
        it "redirects to forked project new merge request" do
          default_params[:branch_name] = "fork-test-1"
          default_params[:create_merge_request] = 1

          put :update, default_params

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
end
