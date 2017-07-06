require 'spec_helper'

describe Projects::MergeRequests::CreationsController do
  let(:project)       { create(:project) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
  let(:user)          { project.owner }
  let(:viewer)        { user }

  before do
    sign_in(viewer)
  end

  describe 'POST #create' do
    def create_merge_request(overrides = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project.to_param,
        merge_request: {
          title: 'Test',
          source_branch: 'feature_conflict',
          target_branch: 'master',
          author: user
        }.merge(overrides)
      }

      post :create, params
    end

    context 'the approvals_before_merge param' do
      let(:created_merge_request) { assigns(:merge_request) }

      before do
        project.update_attributes(approvals_before_merge: 2)
      end

      context 'when it is less than the one in the target project' do
        before do
          create_merge_request(approvals_before_merge: 1)
        end

        it 'sets the param to nil' do
          expect(created_merge_request.approvals_before_merge).to eq(nil)
        end

        it 'creates the merge request' do
          expect(created_merge_request).to be_valid
          expect(response).to redirect_to(project_merge_request_path(project, created_merge_request))
        end
      end

      context 'when it is equal to the one in the target project' do
        before do
          create_merge_request(approvals_before_merge: 2)
        end

        it 'sets the param to nil' do
          expect(created_merge_request.approvals_before_merge).to eq(nil)
        end

        it 'creates the merge request' do
          expect(created_merge_request).to be_valid
          expect(response).to redirect_to(project_merge_request_path(project, created_merge_request))
        end
      end

      context 'when it is greater than the one in the target project' do
        before do
          create_merge_request(approvals_before_merge: 3)
        end

        it 'saves the param in the merge request' do
          expect(created_merge_request.approvals_before_merge).to eq(3)
        end

        it 'creates the merge request' do
          expect(created_merge_request).to be_valid
          expect(response).to redirect_to(project_merge_request_path(project, created_merge_request))
        end
      end

      context 'when the target project is a fork of a deleted project' do
        before do
          original_project = create(:empty_project)
          project.update_attributes(forked_from_project: original_project, approvals_before_merge: 4)
          original_project.update_attributes(pending_delete: true)

          create_merge_request(approvals_before_merge: 3)
        end

        it 'uses the default from the target project' do
          expect(created_merge_request.approvals_before_merge).to eq(nil)
        end

        it 'creates the merge request' do
          expect(created_merge_request).to be_valid
          expect(response).to redirect_to(project_merge_request_path(project, created_merge_request))
        end
      end
    end
  end
end
