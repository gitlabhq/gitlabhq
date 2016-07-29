require 'rails_helper'

describe Projects::ApproversController do
  describe '#destroy' do
    before do
      # Allow redirect_back_or_default to work
      request.env['HTTP_REFERER'] = '/'
    end

    context 'on a merge request' do
      it 'authorizes create_merge_request' do
        merge    = create(:merge_request)
        project  = stub_project(merge.target_project)
        approver = create(:approver, target: merge)

        expect(controller).to receive(:authorize_create_merge_request!)

        go(project, merge_request_id: merge.to_param, id: approver.id)
      end

      it 'destroys the provided approver' do
        merge    = create(:merge_request)
        project  = stub_project(merge.target_project)
        approver = create(:approver, target: merge)

        allow(controller).to receive(:authorize_create_merge_request!)

        expect { go(project, merge_request_id: merge.to_param, id: approver.id) }.
          to change { merge.reload.approvers.count }.by(-1)
      end
    end

    context 'on a project' do
      it 'authorizes admin_project' do
        project  = stub_project
        approver = create(:approver, target: project)

        expect(controller).to receive(:authorize_admin_project!)

        go(project, id: approver.id)
      end

      it 'destroys the provided approver' do
        project  = stub_project
        approver = create(:approver, target: project)

        allow(controller).to receive(:authorize_admin_project!).and_return(true)

        expect { go(project, id: approver.id) }.
          to change { project.approvers.count }.by(-1)
      end
    end

    def go(project, params = {})
      delete :destroy, {
        namespace_id: project.namespace.to_param,
        project_id: project.to_param
      }.merge(params)
    end

    def stub_project(project = build_stubbed(:empty_project))
      project.tap do |p|
        allow(controller).to receive(:project).and_return(p)
      end
    end
  end
end
