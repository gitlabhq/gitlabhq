# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MergeRequests::ContentController, feature_category: :code_review_workflow do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }

  before do
    sign_in(user)
  end

  def do_request(action = :cached_widget, params = {})
    get action, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: merge_request.iid,
      format: :json
    }.merge(params)
  end

  context 'user has access to the project' do
    before do
      expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original

      project.add_maintainer(user)
    end

    describe 'GET cached_widget' do
      it 'renders widget MR entity as json' do
        do_request

        expect(response).to match_response_schema('entities/merge_request_poll_cached_widget')
      end

      it 'closes an MR with moved source project' do
        merge_request.update_column(:source_project_id, nil)

        expect { do_request }.to change { merge_request.reload.open? }.from(true).to(false)
      end
    end

    describe 'GET widget' do
      before do
        merge_request.mark_as_unchecked!
      end

      it 'checks whether the MR can be merged' do
        controller.instance_variable_set(:@merge_request, merge_request)

        expect(merge_request).to receive(:check_mergeability)

        do_request(:widget)

        expect(response).to match_response_schema('entities/merge_request_poll_widget')
        expect(response.headers['Poll-Interval']).to eq('10000')
      end

      context 'merged merge request' do
        let(:merge_request) do
          create(:merged_merge_request, :with_test_reports, target_project: project, source_project: project)
        end

        it 'renders widget MR entity as json' do
          do_request(:widget)

          expect(response).to match_response_schema('entities/merge_request_poll_widget')
          expect(response.headers['Poll-Interval']).to eq('300000')
        end
      end

      context 'with coverage data' do
        let(:merge_request) { create(:merge_request, target_project: project, source_project: project, head_pipeline: head_pipeline) }
        let!(:base_pipeline) { create(:ci_empty_pipeline, project: project, ref: merge_request.target_branch, sha: merge_request.diff_base_sha) }
        let!(:head_pipeline) { create(:ci_empty_pipeline, project: project) }
        let!(:rspec_base) { create(:ci_build, name: 'rspec', coverage: 93.1, pipeline: base_pipeline) }
        let!(:rspec_head) { create(:ci_build, name: 'rspec', coverage: 97.1, pipeline: head_pipeline) }

        it 'renders widget MR entity as json' do
          do_request(:widget)

          expect(response).to match_response_schema('entities/merge_request_poll_widget')
        end
      end
    end
  end

  context 'user does not have access to the project' do
    describe 'GET cached_widget' do
      it 'returns 404' do
        do_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'GET widget' do
      it 'returns 404' do
        do_request(:widget)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
