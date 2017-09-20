require 'spec_helper'

shared_examples 'approvals' do
  def json_response
    JSON.parse(response.body)
  end

  let!(:approver) { create(:approver, target: project) }
  let!(:user_approver) { create(:approver, target: project, user: user) }

  before do
    merge_request.update_attribute :approvals_before_merge, 2
    project.team << [approver.user, :developer]
  end

  describe 'approve' do
    before do
      post :approve,
           namespace_id: project.namespace.to_param,
           project_id: project.to_param,
           id: merge_request.iid,
           format: :json
    end

    it 'approves the merge request' do
      approvals = json_response

      expect(response).to be_success
      expect(approvals['approvals_left']).to eq 1
      expect(approvals['approved_by'].size).to eq 1
      expect(approvals['approved_by'][0]['user']['username']).to eq user.username
      expect(approvals['user_has_approved']).to be true
      expect(approvals['user_can_approve']).to be false
      expect(approvals['suggested_approvers'].size).to eq 1
      expect(approvals['suggested_approvers'][0]['username']).to eq approver.user.username
    end
  end

  describe 'approvals' do
    let!(:approval) { create(:approval, merge_request: merge_request, user: approver.user) }

    before do
      get :approvals,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          id: merge_request.iid,
          format: :json
    end

    it 'shows approval information' do
      approvals = json_response

      expect(response).to be_success
      expect(approvals['approvals_left']).to eq 1
      expect(approvals['approved_by'].size).to eq 1
      expect(approvals['approved_by'][0]['user']['username']).to eq approver.user.username
      expect(approvals['user_has_approved']).to be false
      expect(approvals['user_can_approve']).to be true
      expect(approvals['suggested_approvers'].size).to eq 1
      expect(approvals['suggested_approvers'][0]['username']).to eq user.username
    end
  end

  describe 'unapprove' do
    let!(:approval) { create(:approval, merge_request: merge_request, user: user) }

    before do
      delete :unapprove,
             namespace_id: project.namespace.to_param,
             project_id: project.to_param,
             id: merge_request.iid,
             format: :json
    end

    it 'unapproves the merge request' do
      approvals = json_response

      expect(response).to be_success
      expect(approvals['approvals_left']).to eq 2
      expect(approvals['approved_by']).to be_empty
      expect(approvals['user_has_approved']).to be false
      expect(approvals['user_can_approve']).to be true
      expect(approvals['suggested_approvers'].size).to eq 2
    end
  end
end

describe Projects::MergeRequestsController do
  let(:project)       { create(:project, :repository) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
  let(:user)          { project.owner }
  let(:viewer)        { user }

  before do
    sign_in(viewer)
  end

  it_behaves_like 'approvals'

  describe 'PUT update' do
    before do
      project.update_attributes(approvals_before_merge: 2)
    end

    def update_merge_request(params = {})
      post :update,
           namespace_id: merge_request.target_project.namespace.to_param,
           project_id: merge_request.target_project.to_param,
           id: merge_request.iid,
           merge_request: params
    end

    context 'when the merge request requires approval' do
      before do
        project.update_attributes(approvals_before_merge: 1)
      end

      it_behaves_like 'update invalid issuable', MergeRequest
    end

    context 'overriding approvers per MR' do
      before do
        project.update_attributes(approvals_before_merge: 1)
      end

      context 'enabled' do
        before do
          project.update_attributes(disable_overriding_approvers_per_merge_request: false)
        end

        it 'updates approvals' do
          update_merge_request(approvals_before_merge: 2)

          expect(merge_request.reload.approvals_before_merge).to eq(2)
        end
      end

      context 'disabled' do
        let(:new_approver) { create(:user) }
        let(:new_approver_group) { create(:approver_group) }

        before do
          project.add_developer(new_approver)
          project.update_attributes(disable_overriding_approvers_per_merge_request: true)
        end

        it 'does not update approvals_before_merge' do
          update_merge_request(approvals_before_merge: 2)

          expect(merge_request.reload.approvals_before_merge).to eq(nil)
        end

        it 'does not update approver_ids' do
          update_merge_request(approver_ids: [new_approver].map(&:id).join(','))

          expect(merge_request.reload.approver_ids).to be_empty
        end

        it 'does not update approver_group_ids' do
          update_merge_request(approver_group_ids: [new_approver_group].map(&:id).join(','))

          expect(merge_request.reload.approver_group_ids).to be_empty
        end
      end
    end

    shared_examples 'approvals_before_merge param' do
      before do
        project.update_attributes(approvals_before_merge: 2)
      end

      context 'approvals_before_merge not set for the existing MR' do
        context 'when it is less than the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 1)
          end

          it 'sets the param to nil' do
            expect(merge_request.approvals_before_merge).to eq(nil)
          end

          it 'updates the merge request' do
            expect(merge_request).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is equal to the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 2)
          end

          it 'sets the param to nil' do
            expect(merge_request.reload.approvals_before_merge).to eq(nil)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is greater than the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 3)
          end

          it 'saves the param in the merge request' do
            expect(merge_request.reload.approvals_before_merge).to eq(3)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end
      end

      context 'approvals_before_merge set for the existing MR' do
        before do
          merge_request.update_attribute(:approvals_before_merge, 4)
        end

        context 'when it is not set' do
          before do
            update_merge_request(title: 'New title')
          end

          it 'does not change the merge request' do
            expect(merge_request.reload.approvals_before_merge).to eq(4)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is less than the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 1)
          end

          it 'sets the param to nil' do
            expect(merge_request.reload.approvals_before_merge).to eq(nil)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is equal to the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 2)
          end

          it 'sets the param to nil' do
            expect(merge_request.reload.approvals_before_merge).to eq(nil)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is greater than the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 3)
          end

          it 'saves the param in the merge request' do
            expect(merge_request.reload.approvals_before_merge).to eq(3)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end
      end
    end

    context 'when the MR targets the project' do
      it_behaves_like 'approvals_before_merge param'
    end

    context 'when the project is a fork' do
      let(:upstream) { create(:project, :repository) }
      let(:project) { create(:project, :repository, forked_from_project: upstream) }

      context 'when the MR target upstream' do
        let(:merge_request) { create(:merge_request, title: 'This is targeting upstream', source_project: project, target_project: upstream) }

        before do
          upstream.add_developer(user)
          upstream.update_attributes(approvals_before_merge: 2)
        end

        it_behaves_like 'approvals_before_merge param'
      end

      context 'when the MR target the fork' do
        let(:merge_request) { create(:merge_request, title: 'This is targeting the fork', source_project: project, target_project: project) }

        before do
          project.add_developer(user)
          project.update_attributes(approvals_before_merge: 0)
        end

        it_behaves_like 'approvals_before_merge param'
      end
    end
  end

  describe 'POST merge' do
    let(:base_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: merge_request.iid,
        squash: false,
        format: 'json'
      }
    end

    context 'when the sha parameter matches the source SHA' do
      def merge_with_sha(params = {})
        post :merge, base_params.merge(sha: merge_request.diff_head_sha).merge(params)
      end

      context 'when squash is passed as 1' do
        it 'updates the squash attribute on the MR to true' do
          merge_request.update(squash: false)
          merge_with_sha(squash: '1')

          expect(merge_request.reload.squash).to be_truthy
        end

        it 'merges even when squash is unavailable' do
          stub_licensed_features(merge_request_squash: false)
          merge_with_sha(squash: '1')

          expect(merge_request.reload.squash).to be_falsey
        end
      end

      context 'when squash is passed as 0' do
        it 'updates the squash attribute on the MR to false' do
          merge_request.update(squash: true)
          merge_with_sha(squash: '0')

          expect(merge_request.reload.squash).to be_falsey
        end
      end
    end
  end

  describe 'POST #rebase' do
    def post_rebase
      post :rebase, namespace_id: project.namespace, project_id: project, id: merge_request
    end

    def expect_rebase_worker_for(user)
      expect(RebaseWorker).to receive(:perform_async).with(merge_request.id, user.id)
    end

    context 'successfully' do
      it 'enqeues a RebaseWorker' do
        expect_rebase_worker_for(viewer)

        post_rebase

        expect(response.status).to eq(200)
      end
    end

    context 'approvals pending' do
      let(:project) { create(:project, :repository, approvals_before_merge: 1) }

      it 'returns 200' do
        expect_rebase_worker_for(viewer)

        post_rebase

        expect(response.status).to eq(200)
      end
    end

    context 'with a forked project' do
      let(:fork_project) { create(:project, :repository, forked_from_project: project) }
      let(:fork_owner) { fork_project.owner }

      before do
        merge_request.update!(source_project: fork_project)
        fork_project.add_reporter(user)
      end

      it_behaves_like 'approvals'

      context 'user cannot push to source branch' do
        it 'returns 404' do
          expect_rebase_worker_for(viewer).never

          post_rebase

          expect(response.status).to eq(404)
        end
      end

      context 'user can push to source branch' do
        before do
          project.add_reporter(fork_owner)

          sign_in(fork_owner)
        end

        it 'returns 200' do
          expect_rebase_worker_for(fork_owner)

          post_rebase

          expect(response.status).to eq(200)
        end
      end
    end

    context 'rebase unavailable in license' do
      it 'returns 404' do
        stub_licensed_features(merge_request_rebase: false)
        expect_rebase_worker_for(viewer).never

        post_rebase

        expect(response.status).to eq(404)
      end
    end
  end
end
