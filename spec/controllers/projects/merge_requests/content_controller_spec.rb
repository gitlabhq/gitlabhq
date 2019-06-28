# frozen_string_literal: true

require 'spec_helper'

describe Projects::MergeRequests::ContentController do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }

  before do
    sign_in(user)
  end

  def do_request
    get :widget, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: merge_request.iid,
      format: :json
    }
  end

  describe 'GET widget' do
    context 'user has access to the project' do
      before do
        expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original

        project.add_maintainer(user)
      end

      it 'renders widget MR entity as json' do
        do_request

        expect(response).to match_response_schema('entities/merge_request_widget')
      end

      it 'checks whether the MR can be merged' do
        controller.instance_variable_set(:@merge_request, merge_request)

        expect(merge_request).to receive(:check_mergeability)

        do_request
      end

      it 'closes an MR with moved source project' do
        merge_request.update_column(:source_project_id, nil)

        expect { do_request }.to change { merge_request.reload.open? }.from(true).to(false)
      end
    end

    context 'user does not have access to the project' do
      it 'renders widget MR entity as json' do
        do_request

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
