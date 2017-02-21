require 'rails_helper'

describe Projects::BlobController do
  let(:project) { create(:project, :public, :repository) }
  let(:user)    { create(:user) }

  before do
    project.team << [user, :master]

    sign_in(user)
  end

  describe 'GET diff' do
    render_views

    def do_get(opts = {})
      params = { namespace_id: project.namespace.to_param,
                 project_id: project.to_param,
                 id: 'master/CHANGELOG' }
      get :diff, params.merge(opts)
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

  describe 'PUT update' do
    let(:default_params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project.to_param,
        id: 'master/CHANGELOG',
        target_branch: 'master',
        content: 'Added changes',
        commit_message: 'Update CHANGELOG'
      }
    end

    def blob_after_edit_path
      namespace_project_blob_path(project.namespace, project, 'master/CHANGELOG')
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

        after_edit_path = diffs_namespace_project_merge_request_path(project.namespace, project, merge_request)
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
          default_params[:namespace_id] = forked_project.namespace.to_param
          default_params[:project_id] = forked_project.to_param
        end

        it 'redirects to blob' do
          put :update, default_params

          expect(response).to redirect_to(namespace_project_blob_path(forked_project.namespace, forked_project, 'master/CHANGELOG'))
        end
      end

      context 'when editing on the original repository' do
        it "redirects to forked project new merge request" do
          default_params[:target_branch] = "fork-test-1"
          default_params[:create_merge_request] = 1

          put :update, default_params

          expect(response).to redirect_to(
            new_namespace_project_merge_request_path(
              forked_project.namespace,
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
