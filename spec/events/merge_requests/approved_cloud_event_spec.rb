# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/events/merge_requests/approved_cloud_event'
require_relative '../../support/shared_examples/events/cloud_event_with_schema_shared_examples'
require_relative '../../support/shared_examples/events/merge_request_base_cloud_event_shared_examples'

RSpec.describe MergeRequests::ApprovedCloudEvent, feature_category: :code_suggestions do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request) }

  let(:approved_at) { Time.zone.parse('2026-05-08T10:00:00Z') }
  let(:approval) { instance_double(Approval, created_at: approved_at) }

  describe '.build' do
    let(:event) do
      described_class.build(
        merge_request: merge_request, current_user: user, approval: approval
      )
    end

    it_behaves_like 'a merge request base cloud event'

    it 'sets event_type to :approved' do
      expect(event.event_type).to eq(:approved)
    end

    it 'includes approved_at with microsecond precision' do
      expect(event.event_data[:approved_at]).to eq(approved_at.iso8601(6))
    end
  end

  it_behaves_like 'a cloud event with schema',
    valid_data: {
      merge_request_id: 1,
      merge_request_iid: 10,
      project_id: 100,
      approved_at: '2026-05-08T10:00:00Z'
    },
    missing_required: %i[merge_request_id merge_request_iid project_id approved_at],
    invalid_types: {
      merge_request_id: 'not_an_integer',
      merge_request_iid: 'not_an_integer',
      project_id: 'not_an_integer',
      approved_at: 123
    }
end
