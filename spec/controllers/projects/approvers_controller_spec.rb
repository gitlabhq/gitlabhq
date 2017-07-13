require 'rails_helper'

describe Projects::ApproversController do
  describe '#destroy' do
    let(:user) { create(:user) }
    let(:project) { create(:empty_project) }
    let(:merge_request) { create(:merge_request, source_project: project) }

    before do
      # Allow redirect_back_or_default to work
      request.env['HTTP_REFERER'] = '/'

      project.add_guest(user)
      sign_in(user)
    end

    context 'on a merge request' do
      let!(:approver) { create(:approver, target: merge_request) }

      def destroy_merge_request_approver
        delete :destroy,
               namespace_id: project.namespace.to_param,
               project_id: project.to_param,
               merge_request_id: merge_request.to_param,
               id: approver.id
      end

      context 'when the user cannot update approvers because they do not have access' do
        it 'returns a 404' do
          destroy_merge_request_approver

          expect(response).to have_http_status(404)
        end

        it 'does not destroy any approvers' do
          expect { destroy_merge_request_approver }
            .not_to change { merge_request.reload.approvers.count }
        end
      end

      context 'when the user cannot update approvers because of the project setting' do
        before do
          project.add_developer(user)
          project.update!(disable_overriding_approvers_per_merge_request: true)
        end

        it 'returns a 404' do
          destroy_merge_request_approver

          expect(response).to have_http_status(404)
        end

        it 'does not destroy any approvers' do
          expect { destroy_merge_request_approver }
            .not_to change { merge_request.reload.approvers.count }
        end
      end

      context 'when the user can update approvers' do
        before do
          project.add_developer(user)
        end

        it 'destroys the provided approver' do
          expect { destroy_merge_request_approver }
            .to change { merge_request.reload.approvers.count }.by(-1)
        end
      end
    end

    context 'on a project' do
      let!(:approver) { create(:approver, target: project) }

      def destroy_project_approver
        delete :destroy,
               namespace_id: project.namespace.to_param,
               project_id: project.to_param,
               id: approver.id
      end

      context 'when the user cannot update approvers because they do not have access' do
        it 'returns a 404' do
          destroy_project_approver

          expect(response).to have_http_status(404)
        end

        it 'does not destroy any approvers' do
          expect { destroy_project_approver }
            .not_to change { merge_request.reload.approvers.count }
        end
      end

      context 'when the user can update approvers' do
        before do
          project.add_master(user)
          project.update!(disable_overriding_approvers_per_merge_request: true)
        end

        it 'destroys the provided approver' do
          expect { destroy_project_approver }
            .to change { project.reload.approvers.count }.by(-1)
        end
      end
    end
  end
end
