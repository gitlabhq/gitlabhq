require 'spec_helper'

describe API::MergeRequestApprovals do
  set(:user)          { create(:user) }
  set(:user2)         { create(:user) }
  set(:admin)         { create(:user, :admin) }
  set(:project)       { create(:project, :public, :repository, creator: user, namespace: user.namespace, only_allow_merge_if_pipeline_succeeds: false) }
  set(:merge_request) { create(:merge_request, :simple, author: user, assignee: user, source_project: project, target_project: project, title: "Test", created_at: Time.now) }

  before do
    project.update_attribute(:approvals_before_merge, 2)
  end

  describe 'GET :id/merge_requests/:merge_request_iid/approvals' do
    it 'retrieves the approval status' do
      approver = create :user
      group = create :group
      project.add_developer(approver)
      project.add_developer(create(:user))
      merge_request.approvals.create(user: approver)
      merge_request.approvers.create(user: approver)
      merge_request.approver_groups.create(group: group)

      get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['approvals_required']).to eq 2
      expect(json_response['approvals_left']).to eq 1
      expect(json_response['approved_by'][0]['user']['username']).to eq(approver.username)
      expect(json_response['user_can_approve']).to be false
      expect(json_response['user_has_approved']).to be false
      expect(json_response['approvers'][0]['user']['username']).to eq(approver.username)
      expect(json_response['approver_groups'][0]['group']['name']).to eq(group.name)
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/approvals' do
    shared_examples_for 'user allowed to override approvals required' do
      context 'when disable_overriding_approvers_per_merge_request is false on the project' do
        before do
          project.update_attribute(:disable_overriding_approvers_per_merge_request, false)
        end

        it 'allows you to override approvals required' do
          expect do
            post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", current_user), approvals_required: 5
          end.to change { merge_request.reload.approvals_before_merge }.from(nil).to(5)

          expect(response).to have_gitlab_http_status(201)
          expect(json_response['approvals_required']).to eq(5)
        end

        it 'does not allow approvals required under what the project requires' do
          expect do
            post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", current_user), approvals_required: 1
          end.not_to change { merge_request.reload.approvals_before_merge }

          expect(response).to have_gitlab_http_status(400)
        end

        context 'when project approvals are not enabled' do
          before do
            project.update_attribute(:approvals_before_merge, 0)
          end

          it 'does not allow you to override approvals required' do
            expect do
              post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", current_user), approvals_required: 5
            end.not_to change { merge_request.reload.approvals_before_merge }

            expect(response).to have_gitlab_http_status(400)
          end
        end
      end

      context 'when disable_overriding_approvers_per_merge_request is true on the project' do
        before do
          project.update_attribute(:disable_overriding_approvers_per_merge_request, true)
        end

        it 'does not allow you to override approvals required' do
          expect do
            post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", current_user), approvals_required: 5
          end.not_to change { merge_request.reload.approvals_before_merge }

          expect(response).to have_gitlab_http_status(422)
        end
      end
    end

    context 'as a project admin' do
      it_behaves_like 'user allowed to override approvals required' do
        let(:current_user) { user }
      end
    end

    context 'as a global admin' do
      it_behaves_like 'user allowed to override approvals required' do
        let(:current_user) { admin }
      end
    end

    context 'as a random user' do
      before do
        project.update_attribute(:disable_overriding_approvers_per_merge_request, false)
      end

      it 'does not allow you to override approvals required' do
        expect do
          post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals", user2), approvals_required: 5
        end.not_to change { merge_request.reload.approvals_before_merge }

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe 'PUT :id/merge_requests/:merge_request_iid/approvers' do
    set(:approver) { create(:user) }
    set(:approver_group) { create(:group) }

    RSpec::Matchers.define_negated_matcher :not_change, :change

    shared_examples_for 'user allowed to change approvers' do
      context 'when disable_overriding_approvers_per_merge_request is true on the project' do
        before do
          project.update_attribute(:disable_overriding_approvers_per_merge_request, true)
        end

        it 'does not allow overriding approvers' do
          expect do
            put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvers", current_user),
              approver_ids: [approver.id], approver_group_ids: [approver_group.id]
          end.to not_change { merge_request.approvers.count }.and not_change { merge_request.approver_groups.count }
        end
      end

      context 'when disable_overriding_approvers_per_merge_request is false on the project' do
        before do
          project.update_attribute(:disable_overriding_approvers_per_merge_request, false)
        end

        it 'allows overriding approvers' do
          expect do
            put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvers", current_user),
              approver_ids: [approver.id], approver_group_ids: [approver_group.id]
          end.to change { merge_request.approvers.count }.from(0).to(1)
             .and change { merge_request.approver_groups.count }.from(0).to(1)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['approvers'][0]['user']['username']).to eq(approver.username)
          expect(json_response['approver_groups'][0]['group']['name']).to eq(approver_group.name)
        end

        it 'removes approvers not in the payload' do
          merge_request.approvers.create(user: approver)
          merge_request.approver_groups.create(group: approver_group)

          expect do
            put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvers", current_user),
              { approver_ids: [], approver_group_ids: [] }.to_json, { CONTENT_TYPE: 'application/json' }
          end.to change { merge_request.approvers.count }.from(1).to(0)
             .and change { merge_request.approver_groups.count }.from(1).to(0)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['approvers']).to eq([])
        end
      end
    end

    context 'as a project admin' do
      it_behaves_like 'user allowed to change approvers' do
        let(:current_user) { user }
      end
    end

    context 'as a global admin' do
      it_behaves_like 'user allowed to change approvers' do
        let(:current_user) { admin }
      end
    end

    context 'as a random user' do
      before do
        project.update_attribute(:disable_overriding_approvers_per_merge_request, false)
      end

      it 'does not allow overriding approvers' do
        expect do
          put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvers", user2),
            approver_ids: [approver.id], approver_group_ids: [approver_group.id]
        end.to not_change { merge_request.approvers.count }.and not_change { merge_request.approver_groups.count }

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/approve' do
    context 'as the author of the merge request' do
      before do
        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approve", user)
      end

      it 'returns a 401' do
        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'as a valid approver' do
      set(:approver) { create(:user) }

      before do
        project.add_developer(approver)
        project.add_developer(create(:user))
      end

      def approve(extra_params = {})
        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approve", approver), extra_params
      end

      context 'when the sha param is not set' do
        before do
          approve
        end

        it 'approves the merge request' do
          expect(response).to have_gitlab_http_status(201)
          expect(json_response['approvals_left']).to eq(1)
          expect(json_response['approved_by'][0]['user']['username']).to eq(approver.username)
          expect(json_response['user_has_approved']).to be true
        end
      end

      context 'when the sha param is correct' do
        before do
          approve(sha: merge_request.diff_head_sha)
        end

        it 'approves the merge request' do
          expect(response).to have_gitlab_http_status(201)
          expect(json_response['approvals_left']).to eq(1)
          expect(json_response['approved_by'][0]['user']['username']).to eq(approver.username)
          expect(json_response['user_has_approved']).to be true
        end
      end

      context 'when the sha param is incorrect' do
        before do
          approve(sha: merge_request.diff_head_sha.reverse)
        end

        it 'returns a 409' do
          expect(response).to have_gitlab_http_status(409)
        end

        it 'does not approve the merge request' do
          expect(merge_request.reload.approvals_left).to eq(2)
        end
      end
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/unapprove' do
    context 'as a user who has approved the merge request' do
      set(:approver) { create(:user) }
      set(:unapprover) { create(:user) }

      before do
        project.add_developer(approver)
        project.add_developer(unapprover)
        project.add_developer(create(:user))
        merge_request.approvals.create(user: approver)
        merge_request.approvals.create(user: unapprover)

        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/unapprove", unapprover)
      end

      it 'unapproves the merge request' do
        expect(response).to have_gitlab_http_status(201)
        expect(json_response['approvals_left']).to eq(1)
        usernames = json_response['approved_by'].map { |u| u['user']['username'] }
        expect(usernames).not_to include(unapprover.username)
        expect(usernames.size).to be 1
        expect(json_response['user_has_approved']).to be false
        expect(json_response['user_can_approve']).to be true
      end
    end
  end
end
